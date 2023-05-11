FactoryBot.define do
  factory :children_support_module do
    child
    parent
    support_module
    available_support_module_list { [] }
  end
end
