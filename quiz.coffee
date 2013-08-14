  require ["Embedly"], (embedly) ->

    @questionsColl = new Meteor.Collection("questions")
    @userRepliesColl = new Meteor.Collection("userreplies")

    pecadodetails = [
      {
        name: "gula"
        title: "Gula"
        opposite: "Temperança"
        description: "Gula é o desejo insaciável em geral por comida, bebida. Segundo tal visão, esse pecado também está relacionado ao egoísmo humano: querer ter sempre mais e mais, não se contentando com o que já tem, uma forma de cobiça. Ela seria controlada pelo uso da virtude da temperança. Do latim gula"
      }
      {
        name: "vaidade"
        title: "Vaidade"
        opposite: "Humildade"
        description: "A vaidade (chamada também de orgulho ou soberba) é o desejo de atrair a admiração das outras pessoas. Uma pessoa vaidosa cria uma imagem pessoal para transmitir aos outros, com o objetivo de ser admirada."
      }
      {
        name: "avareza"
        title: "Avareza"
        opposite: "Generosidade"
        description: "É o apego excessivo e descontrolado pelos bens materiais e pelo dinheiro, priorizando-os e deixando Deus em segundo plano. É considerado o pecado mais tolo por se firmar em possibilidades."
      }
      {
        name: "luxuria"
        title: "Luxúria"
        opposite: "Castidade"
        description: "A luxúria (do latim luxuriae) é o desejo passional e egoísta por todo o prazer corporal e material. Também pode ser entendido em seu sentido original: 'deixar-se dominar pelas paixões'."
      }
      {
        name: "ira"
        title: "Ira"
        opposite: "Mansidão"
        description: "A ira é o intenso e descontrolado sentimento de raiva, ódio, rancor que pode ou não gerar sentimento de vingança. É um sentimento mental que conflita o agente causador da ira e o irado."
      }
      {
        name: "preguica"
        title: "Preguiça"
        opposite: "Diligência"
        description: "A Igreja Católica apresenta a preguiça como um dos sete pecados capitais, caracterizado pela pessoa que vive em estado de falta de capricho, de esmero, de empenho, em negligência, desleixo, morosidade, lentidão e moleza, de causa orgânica ou psíquica, que a leva à inatividade acentuada. Aversão ao trabalho, frequentemente associada ao ócio, vadiagem."
      }
      {
        name: "castidade"
        title: "Castidade"
        opposite: "Luxúria"
        description: "Auto-satisfação, simplicidade. Abraçar a moral de si próprio e alcançar pureza de pensamento através de educação e melhorias."
      }
      {
        name: "generosidade"
        title: "Generosidade"
        opposite: "Avareza"
        description: "Despreendimento, largueza. Dar sem esperar receber, uma notabilidade de pensamentos ou ações."
      }
      {
        name: "temperanca"
        title: "Temperança"
        opposite: "Gula"
        description: "Auto-controle, moderação, temperança. Constante demonstração de desagarro aos outros e aos seus arredores, uma prática de abstenção."
      }
      {
        name: "diligencia"
        title: "Diligência"
        opposite: "Preguiça"
        description: "Presteza, ética, decisão, concisão e objetividade. Ações e trabalhos integrados com as próprias crenças."
      }
      {
        name: "caridade"
        title: "Caridade"
        opposite: "Vaidade"
        description: "Auto-satisfação. Compaixão, amizade e simpatia sem causar prejuízos."
      }
      {
        name: "humildade"
        title: "Humildade"
        opposite: "Inveja"
        description: "Modéstia. Comportamento de total respeito ao próximo."
      }
      {
        name: "mansidao"
        title: "Mansidão"
        opposite: "Ira"
        description: "Estado de espírito de alguém que tem controle e domínio sobre seu temperamento e atitudes; calma; paciência; controle da situação; domínio próprio."
      }
    ]
    if (Meteor.isServer)

      questionsColl.remove({})
      #userRepliesColl.remove({})

      userRepliesColl.allow
        insert: (userId, doc) ->
          userId  && doc.owner == userId
      Meteor.users.allow
        update: (userId, upd) ->
          return true

      if (questionsColl.find().count() == 0)

        #console.log()
        questionData = EJSON.parse(Meteor.http.get("https://dl.dropboxusercontent.com/u/8581446/voodooquizquestions2.json").content)


        _.each questionData, (question) ->
          questionsColl.insert(question)
      Meteor.publish("questions", -> questionsColl.find())
      Meteor.publish("userReplies", -> userRepliesColl.find())


    if (Meteor.isClient)
     require "SinVirtueIcons", (icons) ->
      Session.set("currentQuestion", 0)
      Meteor.subscribe("questions")
      Meteor.subscribe("userReplies", ->

        # find first question not answered by user
        lastAnsweredQuestion = Template.quiz.lastAnsweredQuestion()

        console.log("last answered question:"+lastAnsweredQuestion)
        Session.set("currentQuestion", lastAnsweredQuestion + 1) if lastAnsweredQuestion>=0
      )




      Template.quiz.users = ->
        Meteor.users.find()
      Template.quiz.answerImg= -> embedly.getCroppedImageUrl(this.img, 160, 120)
      Template.quiz.lastAnsweredQuestion = ->
        res = userRepliesColl.findOne({owner: Meteor.userId()}, {sort: [["questionNo","desc"]]})?.questionNo
        unless res >=0
          return -1
        res
      Template.quiz.answeredAllQuestions = ->
        console.log("question count:"+Template.quiz.numQuestions())
        Session.get("currentQuestion") >= Template.quiz.numQuestions()

      Template.quiz.pecadoDetails = ->
        _.find(pecadodetails, (detail) ->
          detail.name == Meteor.user().pecado
        )

      Template.quiz.virtudeDetails = ->
        _.find(pecadodetails, (detail) ->
          detail.name == Meteor.user().virtude
        )

      Template.quiz.numQuestions = -> questionsColl.find().count()

      Handlebars.registerHelper "getPecadoImg", ->
        icons.getByVirtueSin("pecado",Meteor.user().pecado)

      Handlebars.registerHelper "getVirtudeImg", ->
        icons.getByVirtueSin("virtude",Meteor.user().virtude)


      Template.quiz.getPecadoPrincipal = ->
         #console.log(userRepliesColl.find({owner: Meteor.userId()}).fetch())
        pecados = {}
        _.each(_.compact(_.pluck(userRepliesColl.find({owner: Meteor.userId()}).fetch(),"result")), (pecado) ->
          pecados[pecado] = (pecados[pecado] ? 0) + 1
        )
        pecs = _.shuffle(_.map(pecados, (p,k) ->
          {pecado: k, count: p}
        ))
        _.max(pecs, (pec) ->
            pec.count
        ).pecado

      Template.quiz.getVirtudePrincipal = ->
        console.log("virtude principal")
        #console.log(userRepliesColl.find({owner: Meteor.userId()}).fetch())
        pecados = {}
        _.each(_.compact(_.pluck(userRepliesColl.find({owner: Meteor.userId()}).fetch(),"virtude")), (pecado) ->
          pecados[pecado] = (pecados[pecado] ? 0) + 1
        )

        pecs = _.shuffle(_.map(pecados, (p,k) ->
          {virtude: k, count: p}
        ))

        _.max(pecs, (pec) ->
            pec.count
        ).virtude



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
      Template.quiz.icons = icons

      self.isTransitioning = false;

      Template.quiz.events =
        'click .clickbutton': (evt) ->
          return if self.isTransitioning;
          self.isTransitioning = true;
          userRepliesColl.insert
            questionNo: Session.get("currentQuestion")
            result: this.result
            virtude: this.virtude
            owner: Meteor.userId()

          console.log(this)
          animEffects = ["hinge","fadeOut","lightSpeedOut","rollOut"]
          $(evt.target).parent().addClass("animated "+animEffects[_.random(animEffects.length-1)])
          Meteor.setTimeout( ->
            Session.set( "currentQuestion", Session.get("currentQuestion")+1 )
            self.isTransitioning = false;
            if Template.quiz.answeredAllQuestions()
              Meteor.users.update(Meteor.userId(), {$set: {pecado: Template.quiz.getPecadoPrincipal()}})
              Meteor.users.update(Meteor.userId(), {$set: {virtude: Template.quiz.getVirtudePrincipal()}})
          , 1500)


