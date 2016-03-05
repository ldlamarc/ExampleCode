#A practical introduction to DDD and OOD coming from standard Rails

##Part 3: Service Objects

Typical responsibilities of a Fat Model.

1. Validating data coming through controllers (validations)
2. Keeping track of the relations between the tables (e.g. has_many)
3. Keeping track of events to be fired in it's lifecycle (e.g. dependent: destroy, after_saves)
4. ~~Constructing queries on the table (e.g. scopes)~~ QueryObjects, [see part 2](https://tothepoint-itco.squarespace.com/journal/2016/1/10/a-practical-introduction-to-ddd-and-ood-coming-from-standard-rails-part-2)
5. Doing calculations on itself or on it's related objects
6. Helping out the controller (e.g. serializing itself to_json)
7. Helping out the views
8. Communicating with other back-end services (e.g. indexing itself for ElasticSearch)
9. ~~Giving meaning to attributes on the relational table (e.g. status: "p" means the document is printed)~~ ValueObjects, [see part 1](https://tothepoint-itco.squarespace.com/config/#/|/journal/2015/11/8/a-practical-introduction-to-ddd-and-ood-coming-from-standard-rails-part-1)

###Introduction

Now that we are warmed up we continue our journey and look at Service Objects. The term 'service' is a very broad concept. Service Objects in a codebase can be used on every layer, on every scale, on every input and for all kinds of functionality. That's why it's essential to categorize services into different types of services with a common denominator. This does not mean you should restrict yourself to these types. Categories are useful as naming conventions in describing the similar groups of services. This facilitates discussing them and reasoning about them. We will hence explore different categories and see how service objects can be used in different ways. To keep the blog post orderly I will link to example code instead of inserting it inline. The code contains further commentary detailling decisions on an implementation level.

### Function the service accomplishes

'Service' being a broad term, there are numerous types of functionality that a service can provide.

#### Parsing/Serializing

When parsing and serialization logic takes up more than a couple of lines of code, or when the code must be shared it might be worth extracting the logic to a separate service object. An example of a ActiveRecord CSV serializer service object which does not require any instance methods on the model itself but instead adds them when needed by module extension can be found [here](#ref).

#### DataRetrieval / DataMapping

ActiveRecord is a 1-on-1 datamapper of a datasource on a model in your domain. An SQL table is an example of such a datasource. But often you need data that is stored in different sources. You want to generate a report for end-users containing information from various sources for example. This could be fixed on a data source level: by constructing (materialized) views in SQL using the scenic gem is one way. But it can also be fixed by using datamapping. A service object which retrieves data and outputs a domain object: a Value Object for example. The need to output an Entity would probable point towards using an ORM: ActiveRecord or the data mapper gem if your Entity is spread out across multiple datasources.

It makes perfect sense to have lightweight PORO DataMappers in your application that output lightweight PORO Value Objects.

An example of such a DataMapper can be found [here](#ref).

#### Processing / Calculating

Imagine the requirement arises to calculate a new state, for example the results of a test are received and trigger the calculation 'did the participants pass the test?'. This would be a prime candidate for a service. If you do these calculations on your ActiveRecord model, via persisting instance methods or callbacks you lose all potential of doing them in bulk and you risk triggering a lot of calls to datastores (queries for example).

These calculations could also probable sometimes be done on a data source layer, by having SQL procedures for example or in a top data source layer (#ref Lambda architecture). One could even argue that it could be the responsibility of the data source layer. But often this logic resides in your application as domain logic on top of your data source layer.

A BatchProcessor example which communicates with a BatchDataMapper can be found [here](#ref).

### Layer at which the service operates

#### Presentation layer

I have never felt the need to use a Service Object for presentational concerns except if you count Serializers. If in Rails you feel like using a Service Object for presentational concerns the Decorator/Exhibit/Presenter patterns are probably better warranted if the logic is tightely coupled to your domain object or helpers if the functionality is less object oriented.

#### Application layer

I think most of the functionality required at application level is handled well by Rails. In most applications I don't think their is a need for application level services. I could imagine that if you deviate from HTTP requests you might need services that translate those HTTP commands to domain logic but most web applications do not fall in that category.

#### Domain layer

This is where Service Objects really shine. If you want the objects to achieve their full potential I would advise keeping good track of the scope of the object. Does it do calculations on an individual object, on a group of objects or on a stream of objects? And to be mindfull of crossing over to the data source layer as mentioned earlier. ActiveRecord is a really powerfull Rails object but also very dangerous for performance. If you provide ActiveRecords as input to your Service Object they might be used to access the data source layer (via associations, validations or save) which would lead to batch processing in the domain layer for example but individual calls and processing on the data source layer (N+1 queries for example). If you have a batch processor in your domain layer (ideal for gorups or streams of objects) I would advise to also using a batchprocessor for your datasource layer. Rails's 'find_each'#ref or 'find_in_batches'#ref are essentialy the right idea, they retrieve data in batches to be handled in batches in your domain/application logic. Typically one would then use includes or preloads to fetch associated data to avoid N+1 queries. But they use a lot of memory, they basically load all the data per entity, this problem aggravates with use of includes or preloads. This also slows down the application as the data takes longer to fetch from the datastores. Most datastores provide higher performance when retrieving, storing or calculating in bulk. Ideally thus a service object in your domain layer that operates on a scale of groups or streams ideally communicates with the data source layer in bulk to.

The same example as in the 'Processing / Calculating' section is referenced [here](#ref).

#### Data Source layer

Here the use of a DataMapper service to communicate with your Service Objects in the Domain layer, see previous section, can give huge performance boosts. ActiveRecord is not really well equiped to work with groups or streams of objects. Efficient data retrieval is also very domain specific so I think it isn't Rails responsibility. PORO's can do a very good job at efficient data mapping. this does not mean you have to reinvent the wheel, you could still use methods provided by ActiveRecord (e.g. pluck, update_all) when they are required as building blocks.

The data mapper used to aid the BatchProcessor can be found [here](#ref).

#### Infrastructure layer

This layer falls out of the scope of this blog post.

### Scale at which the service operates

A service object might operate on an individual object, on a group of objects or on a stream. Identifying the scale is crucial. Ideally to keep the code DRY and consistent stream services use group services which use individual services.

#### Stream level

In Rails this would most likely be an ActiveRecord relation. But it could also be a ElasticSearch index for example. Any service that takes input large enough that it can't be mapped to memory (almost) all at once and realtime could be called a stream processor. Ideally this kind of services split the stream up in batches that they delegate to group level services.

The service which delegates batches to the BatchProcessor can be found [here](#ref).

#### Group level

In Rails this would most likely be an ActiveRecord batch. Again ideally it delegates functionality to individual level services. This is also the level at which data processing is best done most of the time. Retrieving data in batches is a good compromise between speed and memory.

#### Individual level

This is the level at which reasoning is most often done and at which it is the easiest. Most domain logic also requires functionality at an individual Enitity level. If processing at an individual level is not required one can often neglect identity of an object and thus work with Value Objects instead of Entities (even containing the same data except for identity keys). A test result might be an Entity but in context of a service calculating if a person passes the test it becomes a Value Object scoped to that person.

The service which is called by the BatchProcessor on every element can be found [here](#ref).

### Conclusion

A multitude of types of services exist. That's why it's important to have good naming conventions and categories in your project to identify them quickly. As Services can easily cross the boundaries between different layers in your project it is important to be mindful about your boundaries and ideally constrain your services to one layer and to one scale.  Service Objects can especially play a significant role in Rails projects across the domain and data source layer.
