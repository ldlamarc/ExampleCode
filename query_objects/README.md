#Part 2: Query Objects

##Introduction

Typical responsibilities of a Fat Model.

1. Validating data coming through controllers (validations)
2. Keeping track of the relations between the tables (e.g. has_many)
3. Keeping track of events to be fired in it's lifecycle (e.g. dependent: destroy, after_saves)
4. Constructing queries on the table (e.g. scopes)
5. Doing calculations on itself or on it's related objects
6. Helping out the controller (e.g. serializing itself to_json)
7. Helping out the views
8. Communicating with other back-end services (e.g. indexing itself for ElasticSearch)
9. ~~Giving meaning to attributes on the relational table (e.g. status: "p" means the document is printed)~~ with Value Objects, [see part 1](https://tothepoint-itco.squarespace.com/journal/2015/11/8/a-practical-introduction-to-ddd-and-ood-coming-from-standard-rails-part-1)


In our previous article we talked about Value Objects. I chose it as a first topic because it gently introduces us to using non-standard Rails classes in our code to split responsibilities. In this second part I assume the reader has already read part 1 and has already experimented a bit with Value Objects in his own code. They are really the low hanging fruit of refactoring and should be applied first during a refactoring. We shall see through the series that Value Objects can often serve as buiding blocks for the other concepts as well.

But aside from refactoring and splitting responsibilities I often experienced problems in standard Rails constructing complex queries. ActiveRecord is not equipped (yet in Rails 4) to handle ORS, UNIONS, EXCEPTS to name the most important omissions. One can resort to raw SQL or Arel. But than one often faces problems of database portability/reusability in the former and verbose code in the second. This code also ends up in class methods, scopes or relations on ActiveRecord, giving our Object more responsibilities and methods, something we want to avoid.

Query objects are a tool to both construct these complex queries and take over responsibilities from the ActiveRecord.

In the spirit of learning by example, the use case we are going to consider involves selecting records from a database. These records are selected by following multiple conditions that can not be expressed by using simple ANDS. Sometimes these conditions even make it hard to fetch all the records using ORS and ANDS requiring UNIONS and EXCEPTS.

##Example 1

Imagine we have these queries:

users_without_comments:
```ruby
User.includes(:comments).where(comments: {user_id: nil})
```
non_paying_users:
```ruby
User.where(paying: false)
```

These queries select the users who are 'inactive' on our system. We want a query to get them all.

###Alternative 1: Writing raw sql

users_without_comments:
```sql
SELECT * FROM users LEFT JOIN comments ON users.id = comments.user_id WHERE comments.user_id=nil
```
non_paying_users:
```sql
SELECT * FROM users WHERE users.paying=false
```
merging the two:
```sql
SELECT * FROM users LEFT JOIN comments ON users.id = comments.user_id WHERE comments.user_id=nil OR users.paying.false
```

Ok I guess we got it right this time. It actually worked!

Now let's try to write a query to get a different subset of users:

users_with_comments:
```ruby
User.joins(:comments)
```
non_paying_users:
```ruby
User.where(paying: false)
```

user_with_comments:
```sql
SELECT * FROM users INNER JOIN comments ON users.id = comments.user_id
```
non_paying_users:
```sql
SELECT * FROM users WHERE users.paying=false
```
merging the two naively:
```sql
SELECT * FROM users INNER JOIN comments ON users.id = comments.user_id OR users.paying=false
```

Does this work? No it doesn't because it does not include the users who do not have comments but who do have paying status 'false'.

merging the two correctly:
```sql
SELECT * FROM users LEFT JOIN comments ON users.id = comments.user_id WHERE comments.user_id NOT NULL OR users.paying=false
```

This works.

We immediately sense that this process is error prone. This is still a simple example and we would have already written wrong code if we would not have been carefull.
Furthermore the queries or parts of the queries are not easily reusable. We do not have any database portability. If directly inserted into our Model this code also looks ugly and takes up a lot of space.

###Alternative 2: writing raw Arel

The same remarks of alternative 1 roughly apply here as well. Arel does provide more portability. It will probable take up even more space in terms of code, Arel is quite verbose. Some parts might be more easily reusable depending on the situation.


###Alternative 3: plucking and merging in Rails

users_with_comments_ids:
```ruby
User.joins(:comments).pluck(:id)
```
non_paying_users_ids:
```ruby
User.where(paying: false).pluck(:id)
```
Merging:
```ruby
User.where(id: users_with_comments_ids | non_paying_users_ids)
```

This in my opinion is less error prone. But it is often a lot slower. It breaks if you start providing too many ids in the last step. And the output to the logs is also quite ugly and not easily understandable (an SQL query with many ids).

###Alternative 4: select in a select

This is similar to alternative 3 but is more recommendable. Though the previous example is hard to implement this way, it can be usefull in other situations:

```ruby
User.where(id: User.joins(:comments).select(:id))
```

Using select instead of pluck generates one query instead of two.


##Using Query Objects

All the previous options had their disadvantages that we are going to try and solve with Query Objects.

query_helper.rb

```ruby
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
```

inactive_users_query.rb

```ruby
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
```

user.rb

```ruby
class User < ActiveRecord::Base

  scope :inactive, QueryObjects::InactiveUsersQuery

end
```

As you can see we can couple our Query Object to a scope. This is accomplished through the [call method](http://craftingruby.com/posts/2015/06/29/query-objects-through-scopes.html). Delegating this method to a new instance is basically just syntactic sugar for our scope.

We dynamically extend our relation with new scopes using Rails [extending](http://apidock.com/rails/ActiveRecord/QueryMethods/extending). Another example can be found [here](http://helabs.com/blog/2014/01/18/turn-simple-with-query-objects/). This is not somehting I advise for every scenario. If you have a scope that is often used include it in your ActiveRecord. If the scope is only used rarely or in a specific context (for example a rake task) this can be very usefull to avoid littering your ActiveRecord file.

The conditions method keeps track of every query we want in our union. It's very easy to add or remove conditions.

The query helper eventually constructs the UNION query. This is done via raw SQL in this example to keep it simple but can easily be subsituted by [Arel](https://robots.thoughtbot.com/using-arel-to-compose-sql-queries) or any other tool. QueryHelper can be extended with other usefull functions: EXCEPT for example.

The usefulness of Query Objects does certainly not stop here. They can be a gateway to using more [complex features of your database](https://robots.thoughtbot.com/active-record-eager-loading-with-query-objects-and-decorators) not provided by standard Rails as well.


##Tips and Tricks

* I namespaced my Query Objects. This makes it clear for (new) collaborators what the intention and use of the object is.

* You can build upon Query Objects with other scopes: InactiveUsersQuery.call.*insert User scope here* or InactiveUsersQuery.new(User.*insert User scope here*).call. The former will scope your output, the latter will scope your input.

* Coupling Query Objects performing UNIONS, EXCEPTS, etc... in scopes does require precaution. You are deviating from standard Rails and that might have some unforeseen consequences. The method [merge](http://apidock.com/rails/ActiveRecord/SpawnMethods/merge) might not always work (or make sense), methods such as [update_all](http://apidock.com/rails/ActiveRecord/Base/update_all/class) might also forget parts of your query which can be potentially very dangerous. So be sure to test your Query Objects and scopes before using them on production data.


