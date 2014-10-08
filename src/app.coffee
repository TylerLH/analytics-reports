# Load env vars from .env file
dotenv = require 'dotenv'
dotenv.load()

async      = require 'async'
reporter   = require './reporter.coffee'
uploader   = require './dropbox_uploader.coffee'
mailer     = require './mailer.coffee'

# Task handler to generate a report
getReport = (property, callback) ->
  reporter.createCumulativeReport property, {}, callback

reporter.once 'ready', ->
  ## Generate CSV reports for all properties and process the batch when done
  async.each reporter.webProperties, getReport, (err) ->
    console.error err if err?

    # Put the generated reports in Dropbox
    uploader.publish (err) ->
      console.error err if err?
      console.log 'Uploaded reports to Dropbox.'
