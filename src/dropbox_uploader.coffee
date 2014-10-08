Dropbox = require 'dropbox'
moment  = require 'moment'
async   = require 'async'
glob    = require 'glob'
fs      = require 'fs'

class DropboxUploader
  constructor: ->
    @remotePath = "#{moment().format('YYYY/MMMM/YYYY-MM-DD')}"
    @files = glob.sync "#{@remotePath}/**/*.csv", cwd: './reports'
    @client = new Dropbox.Client
      key: process.env.DROPBOX_KEY
      secret: process.env.DROPBOX_SECRET
      token: process.env.DROPBOX_OAUTH_KEY

  publish: (callback) ->
    async.waterfall [
      @checkDir.bind @
      @makeDir.bind @
      @writeFiles.bind @
    ], callback

  checkDir: (cb) ->
    @client.readdir @remotePath, (err, files, info) =>
      cb err if err?
      cb null, info?.isFolder

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

module.exports = new DropboxUploader