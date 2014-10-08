nodemailer = require 'nodemailer'
ses        = require 'nodemailer-ses-transport'
moment     = require 'moment'

class Mailer
  constructor: ->
    sesTransport = ses
      accessKeyId: process.env.AWS_ACCESS_KEY_ID
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      region: 'us-west-2'

    @mailer = nodemailer.createTransport sesTransport

  # Send reports email to list of recipients
  sendReports: ->
    messageParams =
      from: 'Tyler Hughes <tyler@freestoneinternational.com>'
      to: 'iampbt@gmail.com'
      html: '<h1>Hey</h1><p>This is a test</p>'
      text: 'Hey\nThis is a test'
      subject: "Freestone Traffic Report - #{moment().format('YYYY-MM-DD')}"

    @mailer.sendMail messageParams, (err, info) ->
      console.error err if err?
      console.log info

module.exports = new Mailer