do (root = global ? window) ->
  root.Vx     ||= {}
  root.Vx.Lib ||= {}

  class root.Vx.Lib.LogOutput

    constructor: (collection, callback) ->
      @collection = collection
      @callback   = callback
      @reset()

    reset: () ->
      @positionInCollection = 0
      @lastLineHasNL        = true

    process: () ->
      if @isCollectionChanged()
        output = @extractOutput()
        lines  = @extractLines(output)
        @processLines(lines)

    isCollectionChanged: () ->
      @collection.length && @positionInCollection != @collection.length

    processLines: (lines) ->
      for line, idx in lines
        mode = 'newline'

        rep = line.lastIndexOf("\r")
        if rep != -1
          mode = 'replace'
          line = line.substring(rep + 1)

        if idx == 0 and !@lastLineHasNL
          if mode == 'replace'
            @callback("replace", line)
          else
            @callback("append", line)
        else
          @callback("newline", line)

      if @collection[@collection.length - 1].indexOf("\n") != -1
        @lastLineHasNL = true
      else
        @lastLineHasNL = false

    extractOutput: () ->
      output = ""
      newLen = @collection.length

      for i in [@positionInCollection..(newLen - 1)]
        output += @collection[i]

      @positionInCollection = newLen
      @normalize output

    extractLines: (output) ->
      positionInOutput = 0
      lines = []

      loop
        idx = output.indexOf("\n", positionInOutput)

        if idx != -1
          # have new line
          lines.push output.substring(positionInOutput, idx + 1)
          positionInOutput = idx + 1
        else
          # end of buffer
          if positionInOutput < output.length
            # tail in buffer
            lines.push output.substring(positionInOutput)
          break

      lines

    normalize: (str) ->
      str.replace(/\r\n/g, '\n')
         .replace(/\r\r/g, '\r')
         .replace(/\033\[K\r/g, '\r')
         .replace(/\[2K/g, '')
         .replace(/\033\(B/g, '')
         .replace(/\033\[\d+G/g, '')

