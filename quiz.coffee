  require "Embedly", (embedly) ->

    @questionsColl = new Meteor.Collection("questions")
    @userRepliesColl = new Meteor.Collection("userreplies")

    if (Meteor.isServer)

      questionsColl.remove({})
      userRepliesColl.remove({})
      userRepliesColl.allow
        insert: (userId, doc) ->
          userId  && doc.owner == userId
      Meteor.users.allow
        update: (userId, upd) ->
          return true

      if (questionsColl.find().count() == 0)
        questionData = [
          {
            question: "Qual Remédio?"
            type: "pecado"
            answers: [
              {answer: "Biotonico Fontoura", img: "http://farm4.staticflickr.com/3011/2873331615_f2d1310d71.jpg", result: "gula"}
              {answer: "Viagra", img: "http://topnews.ae/images/Viagra_0.jpg", result: "luxuria"}
              {answer: "Rivotril",img:"http://25.media.tumblr.com/tumblr_ln9gfv6ZRc1qf4hg2o1_500.jpg", result: "preguiça"}
              {answer: "Botox", img: "http://multivu.prnewswire.com/mnr/allergan/37769/images/37769-hi-ProductShot2.jpg", result: "vaidade"}
              {answer: "Oxycontin", img: "http://addictionblog.org/wp-content/uploads/2011/08/OxyContin-addiction-statistics2.jpg", result: "ira"}
            ]
          },{
            question: "1Quando aquele vizinho vai pro mesmo caminho e não oferece carona, você:"
            type: "pecado"
            answers: [
              {answer: "Deseja que ele bata no primeiro poste", result: "luxuria"}
              {answer: "Força amizade e vai entrando no carro", result: "luxuria"}
              {answer: "Pergunta se ele pode ser o motorista da rodada enquanto você enche a cara", result: "luxuria"}
              {answer: "Faz nada e pega seu busão caladinho...", result: "luxuria"}
              ]
          },{
            question: "2Quando aquele vizinho vai pro mesmo caminho e não oferece carona, você:"
            type: "pecado"
            answers: [
              {answer: "Deseja que ele bata no primeiro poste", result: "luxuria"}
              {answer: "Força amizade e vai entrando no carro", result: "luxuria"}
              {answer: "Pergunta se ele pode ser o motorista da rodada enquanto você enche a cara", result: "luxuria"}
              {answer: "Faz nada e pega seu busão caladinho...", result: "luxuria"}
            ]
          },{
            question: "3Quando aquele vizinho vai pro mesmo caminho e não oferece carona, você:"
            type: "pecado"
            answers: [
              {answer: "Deseja que ele bata no primeiro poste", result: "luxuria"}
              {answer: "Força amizade e vai entrando no carro", result: "luxuria"}
              {answer: "Pergunta se ele pode ser o motorista da rodada enquanto você enche a cara", result: "luxuria"}
              {answer: "Faz nada e pega seu busão caladinho...", result: "luxuria"}
            ]
          }
        ]
        _.each questionData, (question) ->
          questionsColl.insert(question)
      Meteor.publish("questions", -> questionsColl.find())
      Meteor.publish("userReplies", -> userRepliesColl.find())
      Meteor.publish("users", -> Meteor.users.find({},{fields: {'profile': 1, services : 1, pecado: 1}}))
    if (Meteor.isClient)
      Session.set("currentQuestion", 0)
      Meteor.subscribe("questions")
      Meteor.subscribe("users")
      Meteor.subscribe("userReplies", ->

        # find first question not answered by user
        lastAnsweredQuestion = Template.quiz.lastAnsweredQuestion()
        console.log("last answered question:"+lastAnsweredQuestion)
        Session.set("currentQuestion", lastAnsweredQuestion + 1) if lastAnsweredQuestion>=0
      )




      Template.quiz.users = ->
        Meteor.users.find()
      Template.quiz.answerImg= -> embedly.getCroppedImageUrl(this.img, 200, 150)
      Template.quiz.lastAnsweredQuestion = ->
        res = userRepliesColl.findOne({owner: Meteor.userId()}, {sort: [["questionNo","desc"]]})?.questionNo
        unless res >=0
          return -1
        res
      Template.quiz.answeredAllQuestions = -> (Session.get("currentQuestion") >= Template.quiz.numQuestions())

      Template.quiz.numQuestions = -> questionsColl.find().count()

      Template.quiz.getPecadoPrincipal = ->
         #console.log(userRepliesColl.find({owner: Meteor.userId()}).fetch())
        pecados = {}
        _.each(_.pluck(userRepliesColl.find({owner: Meteor.userId()}).fetch(),"result"), (pecado) ->
          pecados[pecado] = (pecados[pecado] ? 0) + 1
        )
        pecs = _.map(pecados, (p,k) ->
          {pecado: k, count: p}
        )
        _.max(pecs, (pec) ->
            pec.count
        ).pecado

      Template.quiz.helpers(
        currentQuestion: -> questionsColl.find().fetch()[Session.get("currentQuestion")]
        currentQuestionNo:  -> Session.get("currentQuestion") + 1
        currentUser: Meteor.user
        totalQuestions: -> questionsColl.find().count()
        quizProgress: -> Session.get("currentQuestion")/questionsColl.find().count()*100
        iAmCurrentQuestion:  ->
          if (questionsColl.find().fetch()[Session.get("currentQuestion")]._id == this._id)
            "in"
          else
            ""
        currentQuestionId: questionsColl.find().fetch(Session.get("currentQuestion"))
      )

      Template.quiz.questions=questionsColl.find()


      Template.quiz.events =
        'click .clickbutton': (evt) ->

          userRepliesColl.insert
            questionNo: Session.get("currentQuestion")
            result: this.result
            owner: Meteor.userId()

          console.log(this)
          animEffects = ["hinge","fadeOut","lightSpeedOut","rollOut"]
          $(evt.target).parent().addClass("animated "+animEffects[_.random(animEffects.length-1)])
          Meteor.setTimeout( ->
            Session.set( "currentQuestion", Session.get("currentQuestion")+1 )
            if Template.quiz.answeredAllQuestions()
              Meteor.users.update(Meteor.userId(), {$set: {pecado: Template.quiz.getPecadoPrincipal()}})
          , 1500)