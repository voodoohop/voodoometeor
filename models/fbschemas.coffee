define "FBSchemas", [], ->
  event_properties =
      "id": {
        "description": "The event ID.  generic `access_token`, `user_events` or `friends_events`.  `string`.",
        "uri": "http://graph.facebook.com/schema/event#id",
        "identifier": "true"
      },
      "owner": {
        "description": "The profile that created the event. generic `access_token`, `user_events` or `friends_events`. object containing `id` and `name` fields.",
        "uri": "http://graph.facebook.com/schema/event#owner"
      },
      "name": {
        "description": "The event title.  generic `access_token`, `user_events` or `friends_events`.  `string`.",
        "uri": "http://graph.facebook.com/schema/event#name"
      },
      "description": {
        "description": "The long-form description of the event. generic `access_token`, `user_events` or `friends_events`.  `string`.",
        "uri": "http://graph.facebook.com/schema/event#description"
      },
      "start_time": {
        "description": "The start time of the event, as you want it to be displayed on facebook. generic `access_token`, `user_events` or `friends_events`. `string` containing an ISO-8601 formatted date/time (see 'Events Timezone Migration Note' above for details on returned formats)",
        "uri": "http://graph.facebook.com/schema/event#start_time",
        "type": "datetime_no_timezone"
      },
      "end_time": {
        "description": "The end time of the event, if one has been set. generic `access_token`, `user_events` or `friends_events`. `string` containing an ISO-8601 formatted date/time (see 'Events Timezone Migration Note' above for details on returned formats).",
        "uri": "http://graph.facebook.com/schema/event#end_time",
        "type": "datetime_no_timezone"
      },
      "timezone": {
        "uri": "http://graph.facebook.com/schema/event#timezone"
      },
      "location": {
        "description": "The location for this event.  generic `access_token`, `user_events` or `friends_events`. `string`.",
        "uri": "http://graph.facebook.com/schema/event#location"
      },
      "venue": {
        "description": "The location of this event.  generic `access_token`, `user_events` or `friends_events`.  object containing one or more of the following fields: `id`, `street`, `city`, `state`, `zip`, `country`, `latitude`, and `longitude` fields.",
        "uri": "http://graph.facebook.com/schema/event#venue"
      },
      "updated_time": {
        "description": "The last time the event was updated. generic `access_token`, `user_events` or `friends_events`. `string` containing ISO-8601 date-time.",
        "uri": "http://graph.facebook.com/schema/event#updated_time",
        "type": "datetime"
      },
#      "feed": {
#        "description": "This event's wall.",
#        "uri": "http://graph.facebook.com/schema/event#feed",
#        "type": "uri"
#      },
      "picture": {
        "description": "The event's profile picture.",
        "uri": "http://graph.facebook.com/schema/event#picture",
        "type": "uri"
      },
#      "admins": {
#        "uri": "http://graph.facebook.com/schema/event#admins",
#        "type": "uri"
#      },
      "cover": {
        "uri": "http://graph.facebook.com/schema/event#cover"
      },
      "ticket_uri": {
        "description": "The URL to a location to buy tickets for this event (on Events for Pages only).  generic `access_token`, `user_events` or `friends_events`.  `string`",
        "uri": "http://graph.facebook.com/schema/event#ticket_uri"
      },
#      "parent_group": {
#        "uri": "http://graph.facebook.com/schema/event#parent_group"
#      }

  post_properties =
          "id": {
              "description": "The post ID. Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#id",
              "identifier": "true"
          },
          "from": {
              "description": "Information about the user who posted the message. Requires `access_token`. object containing the `name` and Facebook `id` of the user who posted the message.",
              "uri": "http://graph.facebook.com/schema/post#from"
          },
          "to": {
              "description": "Profiles mentioned or targeted in this post. Requires `access_token`. Contains in `data` an `array` of objects, each with the `name` and Facebook `id` of the user.",
              "uri": "http://graph.facebook.com/schema/post#to"
          },
          "with_tags": {
              "description": "Objects (Users, Pages, etc) tagged as being with the publisher of the post (\"Who are you with?\" on Facebook). `read_stream`. `object`s containing `id` and `name` fields, encapsulated in a `data[]` array.",
              "uri": "http://graph.facebook.com/schema/post#with_tags"
          },
          "message": {
              "description": "The message. Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#message"
          },
          "message_tags": {
              "description": "Objects tagged in the message (Users, Pages, etc). Requires `access_token`. `object` containing fields whose names are the indexes to where objects are mentioned in the `message` field; each field in turn is an array containing an `object` with `id`, `name`, `offset`, and `length` fields, where `length` is the length, within the `message` field, of the object mentioned.",
              "uri": "http://graph.facebook.com/schema/post#message_tags"
          },
          "story": {
              "description": "Text of stories not intentionally generated by users, such as those generated when two users become friends; you must have the \"Include recent activity stories\" migration enabled in your app to retrieve these stories. `read_stream`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#story"
          },
          "story_tags": {
              "description": "Objects (Users, Pages, etc) tagged in a non-intentional story; you must have the \"Include recent activity stories\" migration enabled in your app to retrieve these tags. `read_stream`. `object` containing fields whose names are the indexes to where objects are mentioned in the `message` field; each field in turn is an array containing an `object` with `id`, `name`, `offset`, and `length` fields, where `length` is the length, within the `message` field, of the object mentioned.",
              "uri": "http://graph.facebook.com/schema/post#story_tags"
          },
          "picture": {
              "description": "If available, a link to the picture included with this post. Requires `access_token`. `string` containing the URL.",
              "uri": "http://graph.facebook.com/schema/post#picture"
          },
          "full_picture": {
              "uri": "http://graph.facebook.com/schema/post#full_picture"
          },
          "link": {
              "description": "The link attached to this post. Requires `access_token`. `string` containing the URL",
              "uri": "http://graph.facebook.com/schema/post#link"
          },
          "source": {
              "description": "A URL to a Flash movie or video file to be embedded within the post. Requires `access_token`. `string` containing the URL.",
              "uri": "http://graph.facebook.com/schema/post#source"
          },
          "name": {
              "description": "The name of the link. Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#name"
          },
          "caption": {
              "description": "The caption of the link (appears beneath the link name). Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#caption"
          },
          "description": {
              "description": "A description of the link (appears beneath the link caption). Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#description"
          },
          "height": {
              "uri": "http://graph.facebook.com/schema/post#height"
          },
          "width": {
              "uri": "http://graph.facebook.com/schema/post#width"
          },
          "expanded_height": {
              "uri": "http://graph.facebook.com/schema/post#expanded_height"
          },
          "expanded_width": {
              "uri": "http://graph.facebook.com/schema/post#expanded_width"
          },
          "properties": {
              "description": "A list of properties for an uploaded video, for example, the length of the video. Requires `access_token`. `array` of objects containing the `name` and `text`.",
              "uri": "http://graph.facebook.com/schema/post#properties"
          },
          "icon": {
              "description": "A link to an icon representing the type of this post. Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#icon"
          },
          "actions": {
              "description": "A list of available actions on the post (including commenting, liking, and an optional app-specified action). Requires `access_token`. `array` of objects containing the `name` and `link`.",
              "uri": "http://graph.facebook.com/schema/post#actions"
          },
          "privacy": {
              "description": "The privacy settings of the `Post`.  `read_stream`.  A JSON object with fields described [here](/docs/reference/privacy-parameter/).",
              "uri": "http://graph.facebook.com/schema/post#privacy"
          },
          "place": {
              "description": "Location associated with a Post, if any. `read_stream`. `object` containing `id` and `name` of Page associated with this location, and a `location` field containing geographic information such as `latitude`, `longitude`, `country`, and other fields (fields will vary based on geography and availability of information).",
              "uri": "http://graph.facebook.com/schema/post#place"
          },
          "coordinates": {
              "uri": "http://graph.facebook.com/schema/post#coordinates"
          },
          "type": {
              "description": "A string indicating the type for this post (including link, photo, video). Requires `access_token`. `string`.",
              "uri": "http://graph.facebook.com/schema/post#type"
          },
          "status_type": {
              "description": "Type of post. `read_stream`.  One of `mobile_status_update`, `created_note`, `added_photos`, `added_video`, `shared_story`, `created_group`, `created_event`, `wall_post`, `app_created_story`, `published_story`, `tagged_in_photo`, `approved_friend`",
              "uri": "http://graph.facebook.com/schema/post#status_type"
          },
          "object_id": {
              "description": "The Facebook object `id` for an uploaded photo or video. `read_stream`. `number`.",
              "uri": "http://graph.facebook.com/schema/post#object_id"
          },
          "application": {
              "description": "Information about the application this post came from. `read_stream`. object containing the `name` and `id` of the application.",
              "uri": "http://graph.facebook.com/schema/post#application"
          },
          "created_time": {
              "description": "The time the post was initially published. `read_stream`. `string` containing ISO-8601 date-time.",
              "uri": "http://graph.facebook.com/schema/post#created_time",
              "type": "datetime"
          },
          "updated_time": {
              "description": "The time of the last comment on this post. `read_stream`. `string` containing ISO-8601 date-time.",
              "uri": "http://graph.facebook.com/schema/post#updated_time",
              "type": "datetime"
          },
          "shares": {
              "description": "The number of times this post has been shared. `read_stream`. `number` containing count of times post was shared.",
              "uri": "http://graph.facebook.com/schema/post#shares"
          },
          "is_hidden": {
              "uri": "http://graph.facebook.com/schema/post#is_hidden"
          },
          "promotion_status": {
              "uri": "http://graph.facebook.com/schema/post#promotion_status"
          },
          "subscribed": {
              "uri": "http://graph.facebook.com/schema/post#subscribed"
          },
          "is_published": {
              "uri": "http://graph.facebook.com/schema/post#is_published"
          },
          "scheduled_publish_time": {
              "uri": "http://graph.facebook.com/schema/post#scheduled_publish_time"
          },
          "targeting": {
              "uri": "http://graph.facebook.com/schema/post#targeting"
          },
          "parent_id": {
              "uri": "http://graph.facebook.com/schema/post#parent_id"
          },
          "timeline_visibility": {
              "uri": "http://graph.facebook.com/schema/post#timeline_visibility"
          },
          "via": {
              "uri": "http://graph.facebook.com/schema/post#via"
          },
          "feed_targeting": {
              "uri": "http://graph.facebook.com/schema/post#feed_targeting"
          },
          "likes": {
              "description": "The likes on this post.",
              "uri": "http://graph.facebook.com/schema/post#likes",
              "type": "uri"
          },
          "comments": {
              "description": "All of the comments on this post.",
              "uri": "http://graph.facebook.com/schema/post#comments",
              "type": "uri"
          }
  this.post_fields = _.map(post_properties, (k,p) -> p)
  this.event_fields = _.map(event_properties, (k,p) -> p)
  return this