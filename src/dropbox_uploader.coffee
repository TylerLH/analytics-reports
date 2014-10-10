Dropbox = require 'dropbox'
moment  = require 'moment'
async   = require 'async'
glob    = require 'glob'
fs      = require 'fs'

class DropboxUploader
  constructor: ->
    @remotePath = moment().format('YYYY/MMMM/MM-DD-YYYY')
    @files = glob.sync "#{@remotePath}/**/*.{zip,csv}", cwd: './reports'
    @client = new Dropbox.Client
      key: process.env.DROPBOX_KEY
      secret: process.env.DROPBOX_SECRET
      token: process.env.DROPBOX_OAUTH_KEY

  publish: (done) ->
    async.waterfall [
      @checkDir.bind @
      @makeDir.bind @
      @writeFiles.bind @
      @shareUrl.bind @
    ], done

  checkDir: (cb) ->
    @client.readdir @remotePath, (err, files, info) ->

    if err?
      if err.status == Dropbox.ApiError.NOT_FOUND
        cb null, false
      else
        cb err
    cb null, true

  makeDir: (skip, cb) ->
    if skip
      cb null
    else
      @client.mkdir @remotePath, (err, info) ->
        cb err if err?
        cb null

  writeFiles: (cb) ->
    async.each @files, (file, callback) => 
      @writeFile(file, callback)
    , (err) ->
      cb err if err?
      cb null

  writeFile: (file, cb) ->
    @client.writeFile file, fs.readFileSync("./reports/#{file}"), (err, info) ->
      cb(err) if err?
      cb null

  shareUrl: (cb) ->
    @client.makeUrl @remotePath, (err, sharedUrl) ->
      cb err if err?
      cb null, sharedUrl

module.exports = new DropboxUploader