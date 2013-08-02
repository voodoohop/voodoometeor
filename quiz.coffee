

  @questionsColl = new Meteor.Collection("questions")
  if (Meteor.isServer)
    if (questionsColl.find().count() == 0)
      questionData = [
        question: "Qual lugar é mais agravel de Domingo?"
        answers: [
          "Rua Augusta"
          "Bar Brahma"
          "Pça Roosevelt"
        ]
      ]
      _.each questionData, (question) ->
        questionsColl.insert(question)
    Meteor.publish("questions", -> questionsColl.find())

  if (Meteor.isClient)
    Session.set("currentQuestion", 0)
    Meteor.subscribe("questions")

    Template.quiz.helpers(
      currentQuestion: -> questionsColl.find().fetch()[Session.get("currentQuestion")]
      currentUser: Meteor.user
      totalQuestions: -> questionsColl.find().count()
      quizProgress: -> Session.get("currentQuestion")/questionsColl.find().count()*100
    )
    Template.quiz.questions=questions=questionsColl.find()
