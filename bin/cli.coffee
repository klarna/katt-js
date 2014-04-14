#!/usr/bin/env coffee
# Copyright 2013 Klarna AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

fs = require 'fs'
argparse = require 'argparse'
_ = require 'lodash'
katt = require '../'
pkg = require '../package'
test = require 'tape'

parseArgs = (args) ->
  ArgumentParser = argparse.ArgumentParser

  parser = new ArgumentParser
    description: pkg.description
    version: pkg.version
    addHelp: true

  parser.addArgument ['-p', '--params'],
    help: 'Params as JSON string'
    nargs: '1'

  parser.addArgument ['scenarios'],
    help: 'Scenarios as files'
    nargs: '+'

  parser.parseArgs args


exports.createTest = (scenario, params = {}) ->
  params = _.cloneDeep params
  test scenario, (t) ->
    katt.run {scenario, params}, (err, result) ->
      if err?
        return t.error err
      t.equal result.status, 'pass', JSON.stringify result, null, 2
      t.end()


main = exports.main = (args = process.args) ->
  args = parseArgs args
  {params, scenarios} = args
  params = JSON.parse params  if params?
  exports.createTest scenario, params  for scenario in scenarios


main()  if require.main is module
