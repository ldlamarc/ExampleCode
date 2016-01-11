module QueryObjects
  class InactiveUsersQuery
    include QueryHelper

    attr_reader :relation

    class << self
      delegate :call, to: :new
    end

    def call
      @relation.from(union_table("users", *conditions))
    end

    def initialize(relation=User.all)
      @relation = relation.extending(InactiveUserScopes)
    end

    def conditions
      [relation.with_comments, relation.non_paying]
    end

    module InactiveUserScopes
      def with_comments
        includes(:comments).where(comments: {user_id: nil})
      end

      def non_paying
        where(paying: false)
      end
    end
  end
end
