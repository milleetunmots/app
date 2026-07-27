class AdminUser

  class WeakPasswordAuditService

    Finding = Struct.new(:admin_user, :category, keyword_init: true)

    YEARS = %w[2023 2024 2025 2026].freeze
    SUFFIXES = ['', '!', '.', '1234', '123', '@'].freeze
    APP_WORDS = %w[1001mots mots].freeze

    def initialize(scope: AdminUser.all, wordlist_path: nil, thread_count: Concurrent.processor_count, progress: ->(_done, _total) {})
      @scope = scope
      @wordlist_path = wordlist_path
      @thread_count = [thread_count, 1].max
      @progress = progress
    end

    def call
      validate_wordlist_path!
      users = @scope.to_a
      # Précharge la wordlist sur le thread principal : surface tout de suite une
      # erreur de lecture (chemin invalide) au lieu de l'avaler dans un Future, et
      # évite la course de mémoïsation entre threads.
      generic_candidates
      total = users.size
      done = Concurrent::AtomicFixnum.new(0)
      findings = Concurrent::Array.new

      pool = Concurrent::FixedThreadPool.new(@thread_count)
      futures = users.map do |user|
        Concurrent::Future.execute(executor: pool) do
          finding = audit_user(user)
          findings << finding if finding
          @progress.call(done.increment, total)
        end
      end
      futures.each(&:value)
      pool.shutdown
      pool.wait_for_termination

      # Un Future en échec renvoie nil sur #value (exception avalée). Pour un outil
      # de sécurité, un plantage vaut mieux qu'un faux « aucun compte compromis ».
      failure = futures.find(&:rejected?)
      raise failure.reason if failure

      findings.to_a.sort_by { |f| f.admin_user.id }
    end

    private

    def validate_wordlist_path!
      return if @wordlist_path.blank?
      return if File.file?(@wordlist_path)

      raise ArgumentError,
            "Wordlist introuvable : #{@wordlist_path.inspect} (répertoire courant : #{Dir.pwd})"
    end

    # Retourne des paires [candidat, catégorie].
    def targeted_candidates(user)
      name_bases = word_variants(user.name.to_s.delete(' '))
      email_bases = word_variants(user.email.to_s.split('@').first.to_s)
      app_bases = APP_WORDS.flat_map { |w| word_variants(w) }

      pairs = []
      pairs.concat(expand(name_bases, 'ciblé:nom'))
      pairs.concat(expand(email_bases, 'ciblé:email'))
      pairs.concat(expand(app_bases, 'ciblé:app'))
      pairs.uniq { |candidate, _category| candidate }
    end

    # base + variantes de casse
    def word_variants(base)
      return [] if base.blank?

      [base.downcase, base.capitalize, base.upcase].uniq
    end

    # Combine chaque base avec années et suffixes.
    def expand(bases, category)
      bases.flat_map do |base|
        candidates = [base]
        YEARS.each { |y| candidates << "#{base}#{y}" }
        SUFFIXES.each { |s| candidates << "#{base}#{s}" unless s.empty? }
        YEARS.each do |y|
          SUFFIXES.each { |s| candidates << "#{base}#{y}#{s}" unless s.empty? }
        end
        candidates.map { |c| [c, category] }
      end
    end

    def audit_user(user)
      candidates_for(user).each do |candidate, category|
        return Finding.new(admin_user: user, category: category) if match?(user, candidate)
      end
      nil
    end

    # Ciblés d'abord (early exit fréquent), puis génériques.
    def candidates_for(user)
      targeted_candidates(user) + generic_candidates
    end

    def match?(user, candidate)
      return false if candidate.blank?

      Devise::Encryptor.compare(AdminUser, user.encrypted_password, candidate)
    end

    def generic_candidates
      @generic_candidates ||= load_generic_candidates
    end

    def load_generic_candidates
      return [] if @wordlist_path.blank?

      File.foreach(@wordlist_path).filter_map do |line|
        word = line.chomp.strip
        [word, 'générique'] unless word.empty?
      end
    end
  end
end
