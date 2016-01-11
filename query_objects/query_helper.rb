module QueryObjects
  module QueryHelper
    def union_table(name, *relations)
      table(union(*relations), name)
    end

    def union(*relations)
      relations.map{|r| r.to_sql}.join(" UNION ")
    end

    def parenthesis(string)
      "(#{string})"
    end

    def table(content, name)
      "#{parenthesis(content)} \"#{name}\""
    end
  end
end
