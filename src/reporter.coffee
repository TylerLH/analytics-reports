EventEmitter = require('events').EventEmitter
async        = require 'async'
Report       = require 'ga-report'
moment       = require 'moment'
_            = require 'underscore'
csv          = require 'fast-csv'
mkdirp       = require 'mkdirp'
fs           = require 'fs'
path         = require 'path'

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
      callback null, props

  createReport: (opts = {}, callback) ->
    # Get profiles for property
    @report.getProfiles @acctId, opts.property.id, (err, profiles) =>
      options =
        'ids'        : "ga:#{profiles[0].id}"
        'start-date' : '2013-01-01'
        'end-date'   : moment().format 'YYYY-MM-DD'
        'metrics'    : 'ga:users'
        'dimensions' : 'ga:country,ga:region,ga:city'
        'sort'       : '-ga:users,-ga:country,-ga:region'
      _.extend options, opts.query

      # Execute query
      @report.get options, (err, data) =>
        callback(err) if err?

        csvData = [_.map data.columnHeaders, (col) -> col.name]
        if data.rows?
          for row in data.rows
            csvData.push row

        dir = path.dirname opts.path
        mkdirp.sync dir unless fs.exists dir

        csv.writeToPath opts.path, csvData, headers: true
          .on 'error', (err) ->
            callback err
          .on 'finish', ->
            callback null, fs.readFileSync opts.path
          


module.exports = new Reporter