class User < ActiveRecord::Base
  scope :inactive, QueryObjects::InactiveUsersQuery
end
