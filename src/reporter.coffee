EventEmitter = require('events').EventEmitter
async        = require 'async'
Report       = require 'ga-report'
moment       = require 'moment'
_            = require 'underscore'
csv          = require 'fast-csv'
mkdirp       = require 'mkdirp'
fs           = require 'fs'

class Reporter extends EventEmitter
  constructor: ->
    @report = new Report
      username: process.env.GA_USERNAME
      password: process.env.GA_PASSWORD

    @report.once 'ready', @init.bind @

  init: ->
    async.series [
      @getAccountId.bind @
      @getWebProperties.bind @
    ], (err, result) =>
      console.error err if err?
      @emit 'ready'

  getAccountId: (callback) ->
    # Get accounts & set acctId
    @report.getAccounts (err, accts) =>
      callback(err) if err?
      @acctId = accts[0].id
      callback()

  getWebProperties: (callback) ->
    @report.getWebproperties @acctId, (err, props) =>
      callback(err) if err?
      @webProperties = props
      @propertyIds = _.map @webProperties, (prop) -> prop.id
      do callback

  createCumulativeReport: (property, opts = {}, callback) ->
    # Get profiles for property
    @report.getProfiles @acctId, property.id, (err, profiles) =>
      options =
        'ids'        : "ga:#{profiles[0].id}"
        'start-date' : '2013-01-01'
        'end-date'   : moment().format 'YYYY-MM-DD'
        'metrics'    : 'ga:users'
        'dimensions' : 'ga:country,ga:region,ga:city'
        'sort'       : '-ga:users,-ga:country,-ga:region'
      _.extend options, opts

      # Execute query
      @report.get options, (err, data) =>
        callback(err) if err?
        csvData = [_.map data.columnHeaders, (col) -> col.name]
        if data.rows?
          for row in data.rows
            csvData.push row

        # Create the CSV file & write its data
        fileRoot = "./reports/#{moment().format('YYYY/MMMM/YYYY-MM-DD')}/#{property.name}"
        mkdirp.sync fileRoot unless fs.exists fileRoot

        csv
          .writeToPath "#{fileRoot}/CumulativeReport.csv", csvData, headers: true
          .on 'error', (err) ->
            console.error err
          .on 'finish', ->
            do callback

module.exports = new Reporter