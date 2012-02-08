# DLib Backbone.js based objects. Depends on dlib 

#/////////////////////////////////////////////////////////////////////////////
# PageTurner
# 
#   Setup: (from root)
#     (optional) options.menu to hold menu items
#       .active class will be attached to the current tab menu
#       .disable class will be attached to the disabled menu
#       if data-frag exists in menu element, routes will be created/parsed for it.
#       .active menus, if existing, will be treated as default
#     el: hold the tabs.
#     NOTE: The sequence of tabs will match sequence of menu items
# 
#   Methods:
#     show_tab: input tab index (0-based), or use the data-frag string
#     enableTab/disableTab
#   Events:
#     hide_tab(tabid)
#     show_tab(tabid)
#     switched(oldtabid, newtabid)
#   Options:
#     el: The tabs holder (div children are individual tabs)
#     menu: The menu holder (div children are individual menu items)
#     setup: true if initial tab visibility and menu active needs setup
#     route_root: true if hookup with history and setup fragments
#     def_tab: the "default" tab (0 if not specified)
#   Callbacks inside options:
#     validate_transistion_cb(oldtab, newtab)
#       Get called right before tab transition, returns the actual tab to
#       transition to. e.g. return oldtab to prevent transition.
#   Sequence of things when a tab menu is clicked:
#     RTFC
#/////////////////////////////////////////////////////////////////////////////
class ViewPageTurner extends Backbone.View
  _frag_lookup: null # Cached lookup for url fragments
  _last_tab: -1
  
  initialize: (options) ->
    _.bindAll(this, 'show_tab')
    
    options = options || {}
    options.menu = options.menu || '.menu'
    @$tabs = $(@el).children('div')
    @$menu = $(options.menu).first().children('div,a,li')

    if (@options.route_root)
      unless options.def_tab?
        am = @$menu.filter('.active')
        options.def_tab = if (am.length == 1) then am.index() else 0
      $(@$menu[options.def_tab]).data('frag', '')

    @_create_routes()
    
    @$last_tab = @$tabs # healthy hack 
    @$last_menu = @$menu
    @_last_tab = options.def_tab ? -1
    
    @show_tab(options.def_tab || 0) if options.setup
    
    my = this
    @$menu.click ->
      $t = $(this)
      return false if $t.hasClass('disabled')
      my.show_tab($t.index())
      return
      
    return
  
  # Get the current tab. Could be -1 if no tab transition ever happend and there is no default tab
  getCurrentTab: -> @_last_tab
  getTabCount: -> @$tabs.length

  # Return the name (data-frag) of the given tab id
  getTabName: (tabid) -> if tabid == -1 then '' else @_getMenuTabName @$menu[tabid]
  getTabElement: (tabid) -> if tabid == -1 then null else @$tabs[tabid]

  _getMenuTabName: (melm)->
    href = $(melm).attr('href')
    return href.substr(1) if href && href[0] == '#'
    return $(melm).data('frag')

  
  # Disable the menu of a given tabid (does nothing if no menu)
  disableTab: (tab) ->
    tab = @_getTabId(tab)    
    $(@$menu[tab]).addClass('disabled')
    return
    
  enableTab: (tab) ->
    tab = @_getTabId(tab)    
    $(@$menu[tab]).removeClass('disabled')
    return

  isTabDisabled: (tab)-> $(@$menu[@_getTabId(tab)]).hasClass('disabled')

  _getTabId: (tab)->
    # Various attempts to determine the numerical tab value
    tab = @options.def_tab || 0 if (tab == '')
    tab = @_frag_lookup[tab] if (typeof(tab) == 'string' && @_frag_lookup.hasOwnProperty(tab))
    return tab
  
  # Show a given tab, input can be number (index), string (id), or something else
  show_tab: (tab)->
    # Various attempts to determine the numerical tab value
    tab = @_getTabId(tab)    
    return if @isTabDisabled(tab)
    
    # Validate tab switch
    last_tab = @_last_tab
    if ((tab != last_tab) && (@options.validate_transistion_cb)) 
      tab = @options.validate_transistion_cb(last_tab, tab)
    
    # Do the switching anyways, even if last tab is the same.
    @_show_menu(tab)
    @$last_tab?.hide()
    @trigger('hide_tab', last_tab)
    @$last_tab = $(@$tabs[tab])
    
    @trigger('show_tab', tab)
    @$last_tab?.show()
    
    if (@last_tab != tab)
      @last_tab = tab
      @trigger('switched', last_tab, tab)

    @_last_tab = tab
    return
    
  _show_menu: (tab)->
    @$last_menu?.removeClass('active')
    @$last_menu = $(@$menu[tab])
    @$last_menu?.addClass('active')
    
    frag = @getTabName(tab)
    if (frag || frag == '') 
      Backbone.history?.navigate(frag)
    return
  
  _create_routes: ->
    @_frag_lookup = {}
    for menu, i in @$menu
      frag = @_getMenuTabName(menu)
      if (frag || frag == '')
        @_frag_lookup[frag] = i
        Backbone.history = new Backbone.History() unless Backbone.history
        Backbone.history.route(new RegExp('^' + frag + '$'), @show_tab)
    return

window.dlib = window.dlib || {}
window.dlib.ViewPageTurner = ViewPageTurner
