class @Machine
  constructor: (data, @el) ->
    @host = data.host
    @pid = data.pid
    @jobs = data.jobs
    @status = @getStatus()
    @resetFrozenTimeout()

  getStatus: ->
    if @jobs == 0 then "Idle" else "Working"

  resetFrozenTimeout: ->
    clearTimeout(@frozen)
    clearTimeout(@dead)
    @frozen = setTimeout(@markAsFrozen, 6000)

  markAsFrozen: =>
    @status = "Frozen"
    @render()
    @dead = setTimeout(@markAsDead, 6000)

  markAsDead: =>
    @status = "Dead"
    @render()

  markAsAlive: ->
    @status = @getStatus()
    @resetFrozenTimeout()

  render: ->
    row = @el.find("tr[data-pid='#{@pid}']")
    template = Templates.machine(pid: @pid, host: @host, status: @status, jobs: @jobs)

    if row.length == 0
      @el.append(template)
    else
      row.replaceWith(template)
