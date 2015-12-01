
--- === utils.consolidateMenus ===
---
--- A status panel similar to Bartender's is created which can house menus generated by
--- hs.menubar.  Currently it is located in the upper right of the screen and can show
--- any hs.menubar menu.
---
--- It is very limited at present and is more of a "proof-of-concept" and a stage where
--- I can identify things I might want to add or modify in the existing core modules to
--- provide better functionality.
---


local module = {
--[=[
    _NAME        = 'consolidateMenus.lua',
    _VERSION     = 'the 1st digit of Pi/0',
    _URL         = 'https://github.com/asmagill/hammerspoon-config',
    _LICENSE     = [[ See README.md ]]
    _DESCRIPTION = [[

        Build a panel of hs.menubar items elsewhere than the menubar

        Sort of a mini _Bartender_ "proof of concept" sort of thing, but limited
        to our own menus, unfortunately

    ]],
    _TODO        = [[

        [X] Document methods
        [X] timer to check on changes to titles and icons
        [ ] with timer, can also set up autohide/autominimize
        [ ] Allow the panel to be placed elsewhere
        [ ] Allow panel icons, color, etc. to be set via methods
        [X] cleanup menuRemove -- too much repitition
        [X] add close icon to the panel itself

        [ ] test the hell out of this
        [ ] proper __gc; not sure about this one, but it isn't crashing on reload,
            so... probably more important if multiple panels allowed.

    Maybe:

        [ ] add mouse regions which trigger callbacks
              add mouseEnter/mouseLeave to hs.drawing
              invisible rectangles act as region
              allow cursor change as well?
        [ ] update hs.image and/or hs.drawing so it can provide an "inverse" of an
            image to allow mimicking OS X's dark style -- see Core Image filters
        [ ] allow [mod] clicking on items to move them around?
            -- see Cocoa Event Handling Guide, mouse events
               will need to understand dragging events better
        [ ] allow [mod2] clicking to add/remove from status panel/menubar?
        [ ] can hs.drawing be updated so ClickCallback doesn't bring Hammerspoon
            forward? if not, may need to add a module to create regions (invisible
            rectangular areas) which can receive events and handle it that way...
            ugh.

    Probably Not, but "What If..."

        [ ] Can we get non Hammerspoon StatusBarItems?  I know getting Apple's menu
            items will be hard/impossible (even Bartender devs are indicating that
            they may not be able to work around it for 10.11), but some of them are
            actually NSStatusBarItems, like ours...

    ]]
--]=]
}

local menubar = require("hs.menubar")
local fnutils = require("hs.fnutils")
local screen  = require("hs.screen")
local drawing = require("hs.drawing")
local image   = require("hs.image")
local mouse   = require("hs.mouse")
local timer   = require("hs.timer")

local _xtras  = require("hs._asm.extras")

local hMargin, wMargin  = 2, 2
local checkForChanges   = 1.0     -- changes to icons, active monitor, etc.

local boxStroke   = { red = 0.0, green = 0.0, blue = 0.0, alpha = 0.8 }
local boxStrokeW  = 2
local boxFill     = { red = 0.9, green = 0.9, blue = 0.7, alpha = 0.6 }
local boxHeight   = 2 * hMargin + 27 -- screen.mainScreen():frame().y - screen.mainScreen():fullFrame().y
local boxWidth    = boxHeight
local iconHeight  = boxHeight - 2 * hMargin
local iconWidth   = boxWidth  - 2 * wMargin

local myMenuImageOn  = image.imageFromName(image.systemImageNames.RemoveTemplate)
local myMenuImageOff = image.imageFromName(image.systemImageNames.AddTemplate)

local CMIcount = 0

local myMenuItems = {}
local myMenuBar = drawing.rectangle{}:setRoundedRectRadii(wMargin, hMargin)
                                     :setStroke(boxStroke ~= nil)
                                     :setStrokeWidth(boxStrokeW or 0)
                                     :setStrokeColor(boxStroke)
                                     :setFill(boxFill ~= nil)
                                     :setFillColor(boxFill)
                                     :setBehaviorByLabels{"canJoinAllSpaces"}
                                     :setLevel("mainMenu")
                                     :clickCallbackActivating(false)

local panelControl = {
open = { icon = [[
. 1 # # # # # # 2 .
8 . . . . . . . . 3
# . A . . . . E . #
# . . # . . # . . #
# . . . # # . . . #
# . . . # # . . . #
# . . # . . # . . #
# . D . . . . B . #
# . . . . . . . . #
# e # # # # # # f #
# . . . . . . . . #
# . . . . . . a . #
# . . . . # # . . #
# . . # # . . . . #
# . b . . . . . . #
# . . # # . . . . #
# . . . . # # . . #
# . . . . . . c . #
7 . . . . . . . . 4
. 6 # # # # # # 5 .
]], context = {
    { fillColor   = { alpha = 0 } },
    { strokeColor = { red = 0.5 }, lineWidth = 2 },
    { strokeColor = { red = 0.5 }, lineWidth = 2 },
    {
        strokeColor = { green = 0.75 },
        fillColor   = { green = 0.5 , alpha = 1  },
--         shouldClose = false
    }, {  -- safest to always make sure the last one is a decent default
        strokeColor = boxStroke,
        fillColor   = boxFill,
        antialias   = true,
        shouldClose = true
    }
}},
close = {
    icon = [[
. 1 # # # # # # 2 .
8 . . . . . . . . 3
# . A . . . . E . #
# . . # . . # . . #
# . . . # # . . . #
# . . . # # . . . #
# . . # . . # . . #
# . D . . . . B . #
# . . . . . . . . #
# e # # # # # # f #
# . . . . . . . . #
# . a . . . . . . #
# . . # # . . . . #
# . . . . # # . . #
# . . . . . . b . #
# . . . . # # . . #
# . . # # . . . . #
# . c . . . . . . #
7 . . . . . . . . 4
. 6 # # # # # # 5 .
]], context = {
    { fillColor   = { alpha = 0 } },
    { strokeColor = { red = 0.5 }, lineWidth = 2 },
    { strokeColor = { red = 0.5 }, lineWidth = 2 },
    {
        strokeColor = { green = 0.75 },
        fillColor   = { green = 0.5 , alpha = 1  },
--         shouldClose = false
    }, {  -- safest to always make sure the last one is a decent default
        strokeColor = boxStroke,
        fillColor   = boxFill,
        antialias   = true,
        shouldClose = true
    }
}}}

panelControl.open.drawing =  drawing.image({},
                                    image.imageFromASCII(panelControl.open.icon, panelControl.open.context))
                                    :setBehaviorByLabels{"canJoinAllSpaces"}
                                    :orderAbove(myMenuBar)
                                    :setLevel("mainMenu")
                                    :clickCallbackActivating(false)

panelControl.close.drawing = drawing.image({},
                                    image.imageFromASCII(panelControl.close.icon, panelControl.close.context))
                                    :setBehaviorByLabels{"canJoinAllSpaces"}
                                    :orderAbove(myMenuBar)
                                    :setLevel("mainMenu")
                                    :clickCallbackActivating(false)

-- private variables and methods -----------------------------------------

local myMenuVisible = false
local myMenuMinimized = false

local myMenu

local panelToggle = function() return myMenuVisible and module.panelHide() or module.panelShow() end
myMenu = menubar.new():setClickCallback(panelToggle):setIcon(myMenuImageOff)

local minimizeFN = function()
    local mouseY = mouse.getAbsolutePosition().y
    local iconTop = screen.mainScreen():frame().y
    local iconMid = iconTop + boxHeight / 2

    if mouseY < iconMid then
        module.panelToggle()
    else
        module.minToggle()
    end
end

panelControl.open.drawing:setClickCallback(minimizeFN)
panelControl.close.drawing:setClickCallback(minimizeFN)


local monitorRightX = screen.mainScreen():frame().x + screen.mainScreen():frame().w
local monitorTopY   = screen.mainScreen():frame().y
local monitorID     = screen.mainScreen():id()

local dynamicCheck = timer.new(checkForChanges, function()
    if monitorID ~= screen.mainScreen():id() then
        monitorRightX = screen.mainScreen():frame().x + screen.mainScreen():frame().w
        monitorTopY  = screen.mainScreen():frame().y
        if myMenuVisible then
            module.panelShow()
        end
        monitorID = screen.mainScreen():id()
    end
    fnutils.map(myMenuItems, function(a)
--        print("checking...")
        if a.recheckTitle then
            if a.menu:title() ~= a.icon then
                a.icon = a.menu:title()
                a.drawing:setText(a.icon)
            end
        elseif a.recheckIcon then
            if a.menu:icon() ~= a.icon then
                a.icon = a.menu:icon()
                a.drawing:setImage(a.icon)
            end
        end
    end)
end):start()

-- Public interface ------------------------------------------------------

module.menuUserdata = myMenu
module.CMImenuItems = myMenuItems

--- utils.consolidateMenus.panelShow()
--- Function
--- Shows the status panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true
module.myMenuBar = myMenuBar
module.panelShow = function()
    if myMenuMinimized then
        panelControl.close.drawing:hide()
        myMenuBar:setFrame{
            x = monitorRightX - boxWidth / 2,
            y = monitorTopY,
            h = boxHeight,
            w = boxWidth / 2
        }:show()
        panelControl.open.drawing:setFrame{
            x = monitorRightX - boxWidth / 2,
            y = monitorTopY,
            h = boxHeight,
            w = boxWidth / 2
        }:show()
    else
        myMenuBar:setFrame{
            x = monitorRightX - boxWidth * (1 + #myMenuItems),
            y = monitorTopY,
            h = boxHeight,
            w = boxWidth * (1 + #myMenuItems)
        }:show()
        panelControl.open.drawing:hide()
        panelControl.close.drawing:setFrame{
            x = monitorRightX - boxWidth / 2,
            y = monitorTopY,
            h = boxHeight,
            w = boxWidth / 2
        }:show()
        local i = 0
        fnutils.map(myMenuItems, function(menu)
            menu.drawing:setTopLeft{
                x = (monitorRightX) - (#myMenuItems + .5 - i) * boxWidth + wMargin,
                y = monitorTopY + hMargin,
            }:show()
            i = i + 1
        end)
    end

    myMenu:setIcon(myMenuImageOn)
    myMenuVisible = true
    return true
end

--- utils.consolidateMenus.panelHide()
--- Function
--- Hides the status panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true
module.panelHide = function()
    fnutils.map(myMenuItems, function(menu) menu.drawing:hide() end)
    panelControl.open.drawing:hide()
    panelControl.close.drawing:hide()
    myMenuBar:hide()
    myMenu:setIcon(myMenuImageOff)
    myMenuVisible = false
    return true
end

--- utils.consolidateMenus.panelToggle()
--- Function
--- Toggles the visibility of the status panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * true
module.panelToggle = panelToggle

--- utils.consolidateMenus.minToggle()
--- Function
--- Toggles whether or not the panel is minimized.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
module.minToggle = function()
    myMenuMinimized = not myMenuMinimized
    if myMenuVisible then
        if myMenuMinimized then
            module.panelHide()
            myMenuVisible = true -- undo the flag change in hide
        end
        module.panelShow()
    end
end

--- utils.consolidateMenus.addMenu(menu, icon, [position], [autoRemove]) -> table
--- Function
--- Add a menubar item to the status panel.
---
--- Parameters:
---  * menu - the menu item to be added to the status panel.  This must be the menubar userdata returned when the menu was created with hs.menubar.new
---  * icon - an hs.image or string to be displayed as the menus icon in the status panel. Special string names are defined as follows:
---    * "icon" - the current icon defined for the menubar item is used, and the menubar item is polled periodically for updates.
---    * "title" - the current title defined for the menubar item is used, and the menubar item is polled periodically for updates.
---  * position - optional parameter specifying where to insert the new item.  Defaults to 1.
---    * positive numbers start at the left, with 1 being the first position in the panel. The new item is inserted to the left of any existing item at this location.
---    * negative numbers start at the right, with -1 being the last position in the panel. The new item is inserted to the right of any existing item at this location.
---  * autoremove - optional parameter which defaults to false.  If this is true, then the menu will be automatically removed from the menubar when it is inserted into the panel.
---
--- Returns:
---  * a table containing the hs.menubar userdata the hs.drawing userdata, and some other relevant information about this status item.  Usually you will not need this, but it might be handy to cache or save if you intend to remove the menu later, as this is one method of removal which doesn't rely on knowing the menus position.  See utils.consolidateMenus.removeMenu()
---
--- Notes:
---  * Because the status panel uses fixed widths for each item, string titles are usually truncated to their first character.  This may change in the future.
---  * if the menu is autoremoved from the menubar when it is added, it will be returned to the menubar when it is removed from the panel.
module.addMenu = function(menu, icon, position, autoRemove)
    if type(position) == "boolean" and type(autoRemove) == "nil" then
        position, autoRemove = 1, position
    end
    if type(autoRemove) ~= "boolean" then autoRemove = false end
    if type(menu) ~= "userdata" then
        hs.showError("menu must be hs.menubar userdata in addMenu")
        return nil
    end

    if autoRemove and menu == myMenu then
        print("++ Auto removal of the panel toggle is not allowed. Ignoring auto-remove request.")
        autoRemove = false
    end

    if type(icon) ~= "string" and type(icon) ~= "userdata" then
        hs.showError("icon must be hs.image userdata or string in addMenu")
        return nil
    end
    position = position or 1
    if position == 0 then
        showError("position of menu cannot be 0 in addMenu")
        return nil
    end
    if position < 0 then position = #myMenuItems + 1 - (math.abs(position) - 1) end

    CMIcount = CMIcount + 1

    local CMI = setmetatable({ CMIcount = CMIcount},{
        __tostring = function(_)
            return string.format("-- consolidateMenus: (0x%04x)", _.CMIcount)
        end,
    })

    if type(icon) == "string" and not icon:match("^icon$") then
        if icon:match("^title$") then
            CMI.recheckTitle = true
            icon = menu:title()
        end
        CMI.drawing = drawing.text({h = iconHeight, w = iconWidth}, icon)
                             :setTextSize(iconHeight * .75)
                             :setTextColor(boxStroke)
                             :setAlpha(boxStroke.alpha)
                             :clickCallbackActivating(false)
    else
        if type(icon) == "string" then
            CMI.recheckIcon = true
            icon = menu:icon()
        end
        CMI.drawing = drawing.image({h = iconHeight, w = iconWidth}, icon)
                             :setAlpha(boxStroke.alpha)
                             :clickCallbackActivating(false)
    end

    CMI.icon = icon

    CMI.drawing:setBehaviorByLabels{"canJoinAllSpaces"}:orderAbove(myMenuBar)
        :setClickCallback(nil, function()
            CMI.menu:popupMenu{
                x = monitorRightX - (#myMenuItems + .5 - math.floor((monitorRightX - mouse.getAbsolutePosition().x) / boxWidth)) * boxWidth,
                y = monitorTopY + boxHeight + 2 * hMargin,
            }
            dynamicCheck:start() -- if popup takes too long, this can sometimes stop... not sure how to detect yet...
        end):setLevel("mainMenu")

    CMI.menu       = menu
    CMI.autoRemove = autoRemove
    table.insert(myMenuItems, position, CMI)
    if myMenuVisible then module.panelShow() end
    if autoRemove then
        menu:removeFromMenuBar()
    end

    return CMI
end

--- utils.consolidateMenus.removeMenu(menu)
--- Function
--- Remove a menubar item from the status panel.
---
--- Parameters:
---  * menu - the menu item to be removed from the status panel.  The menu can be specified as:
---    * number - its position in the status panel where 1 is the leftmost item
---    * menubar userdata - the actual menubar userdata returned when the menu was created with hs.menubar.new
---    * consolidateMenus table - the return value from the utils.consolidateMenus.addMenu() function.
---
--- Returns:
---  * true if the menuitem was found and removed from the status panel, false if it was not.  An error will also be printed to the Hammerspoon console.
---
--- Notes:
---  * if the menu was autoremoved from the menubar when it was first added, it will be returned to the menubar after its removal from the panel.
module.removeMenu = function(menu)
    local pos = 0

    if type(menu) == "userdata" then   -- by menu object itself
        for i,v in ipairs(myMenuItems) do
            if v.menuUserdata == menu then
                pos = i
                break
            end
        end
    elseif type(menu) == "number" then -- by position in the menu
        if menu > 0 and menu <= #myMenuItems then
            pos = menu
        end
    elseif type(menu) == "table" then  -- by the returned object from addMenu
        for i,v in ipairs(myMenuItems) do
            if v == menu then
                pos = i
                break
            end
        end
    else
        hs.showError("unknown menu type "..type(menu).." passed into removeMenu")
        return false
    end

    if pos == 0 then
        print("++ unable to find menu for removal: "..tostring(menu))
        return false
    else
        myMenuItems[pos].drawing:hide()
        if myMenuItems[pos].autoRemove then myMenuItems[pos].menu:returnToMenuBar() end
        table.remove(myMenuItems, pos)
        if myMenuVisible then module.panelShow() end
        return true
    end
end
-- Return Module Object --------------------------------------------------

-- return setmetatable(module, {
--     __gc = function(_)
--         if myMenuUserdata then
--             myMenuUserdata:delete()
--             myMenu = nil
--         end
--         if myMenuItems then
--             fnutils.map(myMenuItems, function(obj) obj:delete() end)
--             myMenuItems = nil
--         end
--         if myMenuBar then
--             myMenuBar:delete()
--             myMenuBar = nil
--         end
--     end,
-- })

return module