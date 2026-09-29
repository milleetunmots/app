# Spec : refus automatique des inscriptions issues d'une IA générative

## Objectif

Depuis janvier 2025, une dizaine de familles se sont inscrites à l'accompagnement
via une URL proposée par ChatGPT. Ces inscriptions sont **non financées** (aucun
partenaire ne les couvre) et **non ciblées** (elles échappent aux critères
d'orientation du programme).

**Ce qu'on construit :** basculer automatiquement en « Non accompagné »
(`group_status = 'not_supported'`) les enfants dont l'inscription provient d'une
IA générative — tant qu'ils n'ont **pas** commencé leur accompagnement.

**Pour qui :** les cheffes de projet opérations, qui constatent et nettoient ces
inscriptions à la main aujourd'hui. Effet indirect pour les accompagnantes, qui
ne se voient plus attribuer de familles hors cible.

## Règle de détection

Un enfant est considéré comme issu d'une IA générative si la valeur de son
`utm_source` **contient** l'un de ces mots-clés (insensible à la casse) :

| Mot-clé | Valeur attendue typique |
|---|---|
| `chatgpt` | `chatgpt.com` |
| `claude` | `claude.ai` |
| `gemini` | `gemini.google.com` |

`claude` et `gemini` sont ajoutés en prévision, aucun cas constaté à ce jour.
La correspondance est une **sous-chaîne** insensible à la casse pour les trois
(voir *Décisions arrêtées*, point 1).

**Où lire la valeur** — deux sources, dans cet ordre :

1. **Le tag `utm_source=<valeur>`** posé sur l'enfant. Les paramètres d'URL
   commençant par `utm` deviennent des tags à l'inscription
   (`ChildrenController#tags_by_utm_params`, translittérés et en minuscules) :
   `?utm_source=chatgpt.com` → tag `utm_source=chatgpt.com`.
2. **À défaut, le paramètre `utm_source` de `src_url`** — l'URL d'arrivée
   complète, conservée sur l'enfant (`ChildrenController#set_src_url`). Filet
   pour les parcours où le tag n'a pas été posé.

La comparaison porte sur **la valeur** de `utm_source`, pas sur le tag entier.

## Périmètre d'application

Un enfant est éligible au basculement s'il remplit **toutes** ces conditions :

- son `utm_source` correspond à la règle de détection ci-dessus ;
- il n'a **pas** commencé son accompagnement, c'est-à-dire :
  - il n'a pas de cohorte (`group_id IS NULL`), **ou**
  - sa cohorte n'est pas programmée (`groups.is_programmed = false`) ;
- son statut n'est pas déjà `not_supported` (idempotence).

> Rappel du contexte métier : on ne peut pas passer en « Non accompagné » un
> enfant dont l'accompagnement a déjà démarré. La programmation de la cohorte est
> le marqueur retenu pour « a démarré ».

**Traitement rétroactif :** au premier passage, le job traite les enfants déjà en
base qui remplissent ces conditions — dont les familles inscrites depuis janvier
2025 encore non démarrées. Aucune famille déjà accompagnée n'est touchée.

## Deux points d'entrée

### 1. À l'inscription — blocage immédiat

Dans `Child::CreateService`, à côté du mécanisme existant
(`set_not_supported` / `add_target_tag('filtre-diplome-KO')`). L'enfant n'entre
jamais dans le circuit d'accompagnement.

### 2. Job quotidien — filet de sécurité

Rattrape ce qui échappe au chemin d'inscription : imports, Typeform, reprises
de données, et le stock existant. Tourne tous les jours.

Ces deux entrées partagent **la même règle de détection**, extraite dans un objet
unique pour éviter toute divergence.

## Effets attendus

Sur la fiche enfant, **le seul changement est `group_status = 'not_supported'`**.

Deux conséquences en découlent automatiquement, vérifiées dans le code :

| Conséquence | Mécanisme |
|---|---|
| L'enfant est détaché de sa cohorte | `Child#remove_group` (callback `after_update`) |
| Il disparaît des listes d'accompagnement | `Child.supported` exclut `not_supported` |
| Les campagnes de groupe l'ignorent | `ProgramMessageService` filtre sur `group_status: ['active']` |

Il n'est donc **pas** nécessaire de décocher `should_contact_parent1/2`.

### Correctif requis : le SMS de bienvenue

⚠️ Le statut `not_supported` **ne suffit pas** à couper tous les envois.
`Child::CreateService#send_form_by_sms` expédie le SMS de bienvenue contenant le
lien Typeform via `Child::SendInitialFormSmsJob`, qui ne consulte jamais
`group_status` — sa seule garde est le tag `filtre-diplome-KO`. Sans correctif,
une famille venue de ChatGPT serait écartée **et** invitée à remplir le
questionnaire.

**Décision :** `send_form_by_sms` sort dès que l'enfant est `not_supported`,
quelle qu'en soit la raison. Garde générale, qui couvre aussi tout futur motif de
refus. La garde `filtre-diplome-KO` existante devient redondante mais reste en
place (inoffensive, et le tag sert encore ailleurs).

Ce correctif ne concerne que le chemin d'inscription : pour les enfants déjà en
base traités par le job, le SMS de bienvenue est déjà parti depuis longtemps.

## Critères d'acceptation

1. Une inscription avec `?utm_source=chatgpt.com` ressort avec le statut
   « Non accompagné » immédiatement, sans cohorte.
2. Idem pour `claude.ai`, `gemini.google.com`, et pour toute valeur contenant
   `chatgpt`, `claude` ou `gemini` (ex. `chatgpt`, `ChatGPT.com`).
3. Une inscription avec un `utm_source` légitime (`caf01`, `pmi80`, vide,
   absent) n'est **pas** affectée.
4. Le job quotidien bascule un enfant sans cohorte qui correspond à la règle.
5. Le job quotidien bascule un enfant dans une cohorte **non programmée**.
6. Le job quotidien **ne touche pas** un enfant dans une cohorte **programmée**,
   quel que soit son `utm_source`.
7. Le job est idempotent : deux passages consécutifs ne produisent aucun
   changement supplémentaire et aucune erreur.
8. Un enfant dont le tag est absent mais dont `src_url` contient
   `utm_source=chatgpt.com` est bien détecté.
9. Une inscription écartée par la règle **ne reçoit pas** le SMS de bienvenue
   avec le lien Typeform.
10. Une inscription légitime reçoit toujours ce SMS (non-régression).

## Architecture visée

Le dépôt a un patron établi pour les traitements planifiés — on le suit :

```
app/jobs/child/<nom>_job.rb          → déclenche le service, rien d'autre
app/services/child/<nom>_service.rb  → toute la logique
config/sidekiq.yml                   → entrée cron
spec/services/child/<nom>_spec.rb    → tests du service
```

Référence à imiter : `Child::StopUnassignedNumberJob` →
`Child::StopUnassignedNumberService` → `spec/services/child/stop_unassigned_number_service_spec.rb`.

**Créneau cron proposé :** `45 1 * * *` (1h45). Libre, et placé **avant**
`Child::AddWaitingChildrenToGroupJob` (lundi 2h00) pour que ces enfants ne soient
pas affectés à une cohorte juste avant d'être écartés.

## Stratégie de test

RSpec + FactoryBot, conformément à `CLAUDE.md`.

| Niveau | Emplacement | Couvre |
|---|---|---|
| Service | `spec/services/child/` | règle de détection, éligibilité, idempotence (critères 4-8) |
| Service | `spec/services/child/create_service_spec.rb` | blocage à l'inscription (critères 1-3) |

Chaque critère d'acceptation ci-dessus doit correspondre à au moins un exemple.
Les cas négatifs (critères 3 et 6) sont les plus importants : ce sont eux qui
protègent les familles légitimes.

## Boundaries

**Toujours :**
- Écrire le test avant le code (Prove-It pour toute régression).
- Lancer `bundle exec rspec` en entier avant de committer.
- Garder une **seule** implémentation de la règle de détection, partagée par les
  deux points d'entrée.

**Demander avant :**
- Toute modification du schéma (migration).
- Tout élargissement de la liste de mots-clés au-delà des trois spécifiés.
- Toute exécution du job sur la base de production.

**Jamais :**
- Toucher aux enfants dont la cohorte est programmée.
- Basculer un enfant en `not_supported` sans qu'il corresponde à la règle.
- Supprimer ou désactiver un test existant pour faire passer la suite.

## Décisions arrêtées

1. **Correspondance par sous-chaîne pour les trois mots-clés.** Le risque de faux
   positif sur `claude` (prénom courant, commune de Saint-Claude dans le Jura) a
   été signalé et **assumé** : la couverture des variantes futures prime. Le log
   applicatif ci-dessous est le garde-fou — c'est lui qui permettra de repérer un
   faux positif après coup.
2. **Liste de mots-clés : constante Ruby** dans le service, couverte par les
   tests. Ajouter une IA demande un déploiement, ce qui est acceptable vu la
   stabilité des trois valeurs.
3. **Trace : log applicatif.** Le service logue chaque enfant basculé avec son
   `utm_source`, plus un total par passage. Aucun effet supplémentaire sur la
   fiche enfant — le « rien d'autre » de la section *Effets attendus* tient.
