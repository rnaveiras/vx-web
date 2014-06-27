angular.module('Vx').
  factory "localStorage", ['$window', ($window) ->

    storage =
      try
        $window.localStorage != null && $window.localStorage
      catch
        false

    exists = () ->
      storage != false

    get: (key) ->
      if exists()
        storage.getItem(key)

    set: (key, value) ->
      if exists()
        storage.setItem(key, value)
  ]
