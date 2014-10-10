# Load env vars from .env file
dotenv = require 'dotenv'
dotenv.load()

config      = require('./../config.json')[process.env.NODE_ENV || 'development']
async       = require 'async'
reporter    = require './reporter.coffee'
dropbox     = require './dropbox_uploader.coffee'
mailer      = require './mailer.coffee'
fs          = require 'fs'
moment      = require 'moment'
path        = require 'path'

zip          = new require('node-zip')()
folderFormat = moment().format('YYYY/MMMM/MM-DD-YYYY')

getReport = (property, done) ->
  filePath = "./reports/#{folderFormat}/#{property.name}/CumulativeTrafficByLocation.csv"
  reporter.createReport
    path: filePath
    property: property
  , (err, result) ->
    done err if err?
    zip.file filePath.replace("./reports/#{folderFormat}", ''), result, createFolders: true
    done null, result

reporter.once 'ready', ->
  console.log 'Getting reports...'
  # Get the reports and build a zip file of them
  async.map reporter.webProperties, getReport, (err, files) ->
    throw err if err?

    # Generate and save zip file
    console.log 'Saving zip file...'
    zipData = zip.generate type: 'nodebuffer'
    fs.writeFileSync "./reports/#{folderFormat}/TrafficReports_#{moment().format('MM-DD-YYYY')}.zip", zipData

    # Publish reports & zip to Dropbox
    dropbox.publish (err) ->
      throw err if err?
      console.log 'Published to Dropbox.'

      mailer.sendReports (err) ->
        console.log 'Reports sent.'
        console.log 'Finished!'
