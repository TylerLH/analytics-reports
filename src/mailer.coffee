nodemailer = require 'nodemailer'
markdown   = require('nodemailer-markdown').markdown
ses        = require 'nodemailer-ses-transport'
moment     = require 'moment'
config     = require('./../config.json')[process.env.NODE_ENV || 'development']
_          = require 'underscore'

class Mailer
  constructor: ->
    sesTransport = ses
      accessKeyId: process.env.AWS_ACCESS_KEY_ID
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      region: 'us-west-2'

    @transporter = nodemailer.createTransport sesTransport
    @transporter.use 'compile', markdown()

  buildRecipientList: ->
    _.map config.recipients, (recipient) -> "#{recipient.name} <#{recipient.email}>"

  # Send reports email to list of recipients
  sendReports: (done) ->
    messageParams =
      from: 'Tyler Hughes <tyler@freestoneinternational.com>'
      to: @buildRecipientList()
      markdown: """
        Here's the latest batch of traffic reports for all Freestone web properties.

        A .zip file is attached for download, or you can view the reports in Dropbox at this URL: 
      """
      subject: "Freestone Traffic Reports for #{moment().format('MMMM Do YYYY')}"

    @transporter.sendMail messageParams, (err, info) ->
      done err if err?
      done null, info

module.exports = new Mailer