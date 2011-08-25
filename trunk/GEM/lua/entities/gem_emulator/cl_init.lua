include("shared.lua")

--------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
--------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: Initialize
-- Desc: -
----------------------------------------------------------------------
function ENT:Initialize()
	self.ErrorMessage = ""
	self.HasError = false
	
	self.MenuItems = {}
	self.HasMenuItems = false
	
	self:LoadMenu( "Main" )
end

----------------------------------------------------------------------
-- Name: OnRemove
-- Desc: -
----------------------------------------------------------------------
function ENT:OnRemove()
	self:FinalizeROM()
end

function ENT:Error( msg )
	self.HasError = true
	self.ErrorMessage = msg
	self:LoadMenu( "Error" )
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------
-- Name: SimpleWordWrap
---------------------------------
local function simpleWordWrap( msg, w )
	local newmsg = ""
	local temp = ""
	surface.SetFont( "Trebuchet18" )
	for i=1,#msg do
		if surface.GetTextSize( temp .. msg:sub(i,i) ) >= w then
			newmsg = newmsg .. temp .. "\n"
			temp = msg:sub(i,i)
		else
			temp = temp .. msg:sub(i,i)
		end
	end
	newmsg = newmsg .. temp
	return newmsg
end

---------------------------------
-- Name: drawTextWithNewlines
---------------------------------
local function drawTextWithNewlines( msg, x, y )
	if not msg:find( "\n" ) then
		surface.SetTextPos( x, y )
		surface.DrawText( msg )
	else
		local data = string.Explode( "\n", msg )
		local w, h = surface.GetTextSize( data[1] )
		local ofs = 0
		for k,v in pairs( data ) do
			surface.SetTextPos( x, y + ofs )
			surface.DrawText( v )
			ofs = ofs + h
		end
	end
end

---------------------------------
-- Name: inrange
---------------------------------
local function inrange( x1, y1, x2, y2, x3, y3 )
	if x1 < x2 then return false end
	if y1 < y2 then return false end
	if x1 > x3 then return false end
	if y1 > y3 then return false end
	
	return true
end

---------------------------------
-- Keys table
---------------------------------
local keys = {}
for k,v in pairs( _E ) do
	if k:sub(1,4) == "KEY_" then
		keys[k] = v
	end
end

local validKeys = { A = true, B = true, Start = true, Select = true, Up = true, Left = true, Down = true, Right = true, Exit = true }

--------------------------------------------------------------------------------------------------------------------------------------------
-- Drawing functions
--------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: Draw
-- Desc: -
----------------------------------------------------------------------
local draw_positions = {
	-- Model									Position offset	 		Angle offset  		Scale
	["models/hunter/plates/plate1x1.mdl"] = { Vector(-23.725,-23.725,1.8), Angle(0,90,0), 0.1854 },
	["models/hunter/plates/plate2x2.mdl"] = { Vector(-47.45,-47.45,1.8), Angle(0,90,0), 0.3707 },
	["models/hunter/plates/plate3x3.mdl"] = { Vector(-71.175,-71.175,1.8), Angle(0,90,0), 0.5561 },
	["models/hunter/plates/plate4x4.mdl"] = { Vector(-94.9,-94.9,1.8), Angle(0,90,0), 0.7414 },
}

local matscreen = CreateMaterial("GEMRT","UnlitGeneric",{
	["$vertexcolor"] = 1,
	["$vertexalpha"] = 1,
	["$ignorez"] = 1,
	["$nolod"] = 1,
})

matscreen:SetMaterialTexture( "$basetexture", GetRenderTarget("gem_rt_1", 256, 256) )

local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetMaterial = surface.SetMaterial
local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D

function ENT:Draw()
	self:DrawModel()
	
	if LocalPlayer():GetPos():Distance( self:GetPos() ) > 1000 then return end
	if not self:GetPly() then return end
	
	local draw_data = draw_positions[self:GetModel()]
	if not draw_data then return end
	
	if self.HasMenuItems then
			
		local pos, ang, scale = draw_data[1], draw_data[2], draw_data[3]
		cam_Start3D2D( self:LocalToWorld( pos ), self:LocalToWorldAngles( ang ), scale )
		
			-- Temporary
			local ok, msg = pcall( self.DrawMenu, self )
			if not ok then
				ErrorNoHalt( "error: " .. tostring(msg) )
			end
			
			--self:DrawButtons()
		
		cam_End3D2D()
		
	elseif self.Emulator and not self.HasError then
		
		self.Emulator:Draw()
		
		local pos, ang, scale = draw_data[1], draw_data[2], draw_data[3]
		cam_Start3D2D( self:LocalToWorld( pos ), self:LocalToWorldAngles( ang ), scale )
		
			surface_SetDrawColor( 255,255,255,255 )
			surface_SetMaterial( matscreen )
			surface_DrawTexturedRect( 0,0,256,256 )
			
		cam_End3D2D()

	end
end

local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_DrawRect = surface.DrawRect
local surface_GetTextSize = surface.GetTextSize
local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor

function ENT:DrawMenu()
	surface_SetDrawColor( 0,0,0,255 )
	surface_DrawRect( 0,0,256,256 )
	surface_SetFont( "Trebuchet18" )

	for i=1,#self.MenuItems do
		local item = self.MenuItems[i]
		
		if item.type == "button" then
			surface_SetDrawColor( 200,50,50,255 )
			surface_DrawOutlinedRect( item.x, item.y, item.w, item.h )
			
			surface_SetDrawColor( 100, 0, 0, item.hover and 50 or 150 )
			surface_DrawRect( item.x, item.y, item.w, item.h )
			
			surface_SetTextColor( 0,0,0,255 )
			drawTextWithNewlines( item.text, item.textx, item.y )
		else -- label
			surface_SetTextColor( 150,0,0,255 )
			drawTextWithNewlines( item.text, item.x, item.y )
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- Button system functions
--------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: CreateButton
-- Desc: -
----------------------------------------------------------------------
function ENT:CreateButton( text, onPress, w, h, x, y, align_left )
	surface_SetFont( "Trebuchet18" )
	local textw, texth = surface_GetTextSize( text )
	
	x = x or 128
	y = y or #self.MenuItems * 20 + 40
	
	w = w or textw + 8
	h = h or texth
	
	if not align_left then
		x = x - w / 2
		y = y - h / 2
	end

	self.MenuItems[#self.MenuItems+1] = { type = "button", x = x, y = y, w = w, h = h, text = text, onPress = onPress, textx = x + w/2 - textw/2 }
	
	self.HasMenuItems = true
	
	return self.MenuItems[#self.MenuItems]
end

----------------------------------------------------------------------
-- Name: CreateLabel
-- Desc: -
----------------------------------------------------------------------
function ENT:CreateLabel( text, x, y, align_left )
	surface_SetFont( "Trebuchet18" )
	local textw, texth = surface_GetTextSize( text )
	
	x = x or 128
	y = y or #self.MenuItems * 20 + 40
	
	if not align_left then
		x = x - textw / 2
		y = y - texth / 2
	end

	self.MenuItems[#self.MenuItems+1] = { type = "label", x = x, y = y, text = text }
	
	self.HasMenuItems = true
	
	return self.MenuItems[#self.MenuItems]
end

----------------------------------------------------------------------
-- Name: ClearItems
-- Desc: -
----------------------------------------------------------------------
function ENT:ClearMenuItems()
	self.MenuItems = {}
	self.HasMenuItems = false
end

----------------------------------------------------------------------
-- Name: LoadROMList
-- Desc: Lists all available roms on the client in the specified folder
----------------------------------------------------------------------
function ENT:LoadROMList( fld )
	-- Create folders if they don't exist
	if not file.IsDir( "gem_emulator" ) then
		file.CreateDir( "gem_emulator" )
	end
	
	if not file.IsDir( "gem_emulator/8080" ) then
		file.CreateDir( "gem_emulator/8080" )
	end
	
	if not file.IsDir( "gem_emulator/GBZ80" ) then
		file.CreateDir( "gem_emulator/GBZ80" )
	end

	local folder = "gem_emulator/" .. fld
	
	local files = file.Find( folder .. "/*.txt" )
	
	if #files == 0 then
		self:CreateButton( "Back", function( self ) self:LoadMenu( "ROMMenu" ) end )
		return
	end
	
	local pages = {}
	local n = 1
	
	local temp = {}
	
	for k,v in pairs( files ) do
		temp[#temp+1] = v
		if n == 1 and #temp == 10 then -- we can fit one more in the first page because there is no "prev" button
			pages[n] = temp
			temp = {}
			n = n + 1
		elseif n > 1 and #temp == 9 then
			pages[n] = temp
			-- If there's only one left, add that one too (because we can fit one more on the last page since there is no "next" button)
			if k == #files-1 then
				local page = pages[n]
				page[#page+1] = files[#files]
				break
			end
			temp = {}
			n = n + 1
		end
	end
	if #temp > 0 then -- Add any stragglers
		pages[n] = temp
	end
	
	for pagenum,page in pairs( pages ) do
		for key,curfile in pairs( page ) do
			pages[pagenum][key] = { text = curfile, onPress = function( self ) self:LoadROM( folder .. "/" .. curfile, fld ) end }
		end
		
		if pagenum > 1 then 
			page[#page+1] = { text = "Prev page", onPress = function( self ) self:UnwrapROMListTable( pages[pagenum-1] ) end }
		end
		
		if pagenum < #pages then
			page[#page+1] = { text = "Next page", onPress = function( self ) self:UnwrapROMListTable( pages[pagenum+1] ) end }
		end
		
		page[#page+1] = { text = "Back", onPress = function( self ) self:LoadMenu( "ROMMenu" ) end }
	end
	
	self:UnwrapROMListTable( pages[1] )
end

-------------------------------------
-- Name: UnwrapROMListTable
-- Desc: Helper Function
-------------------------------------
function ENT:UnwrapROMListTable( t )
	self:ClearMenuItems()
	
	surface_SetFont( "Trebuchet18" )
	local max
	local h
	for k,v in pairs( t ) do
		local w, _h = surface_GetTextSize( v.text ) + 8
		if not max or w > max then max = w end
		h = _h
	end
	
	local y = 18
	for k,v in pairs( t ) do
		self:CreateButton( v.text, v.onPress, max, nil, nil, y )
		y = y + 20
	end
end

----------------------------------------------------------------------
-- Name: LoadMenu
-- Desc: -
----------------------------------------------------------------------
local menus = {
	Main = function( self )
		self:ClearMenuItems()
		self:CreateLabel( "Main Menu" )
		if self.Emulator then
			self:CreateButton( "Resume", 	function( self ) self:ClearMenuItems() self:Enter() end, 128 )
		end
		self:CreateButton( "Select ROM", 	function( self ) self:LoadMenu( "ROMMenu" ) 	end, 128 )
		self:CreateButton( "Key Bindings",  function( self ) self:LoadMenu( "KeyBindings" ) end, 128 )
		self:CreateButton( "Screen Size",  	function( self ) self:LoadMenu( "ScreenSize" ) 	end, 128 )
	end,
	Error = function( self )
		self:ClearMenuItems()
		self:CreateLabel( "An error has occured!" )
		local item = self:CreateButton( "Print error message to console", 	function( self ) ErrorNoHalt( self.ErrorMessage ) 				end )
		self:CreateButton( "Restart Emulator", 								function( self ) self:FinalizeROM() self:LoadMenu( "Main" ) 	end, item.w )
	end,
	ROMMenu = function( self )
		self:ClearMenuItems()
		self:CreateLabel( "Select Emulator Type" )
		self:CreateButton( "8080", function( self ) self:ClearMenuItems() self:LoadROMList( "8080" ) end, 48 )
		self:CreateButton( "GBZ80", function( self ) self:ClearMenuItems() self:LoadROMList( "GBZ80" ) end, 48 )
		
		self:CreateButton( "Back", function( self ) self:LoadMenu( "Main" ) end, 48 )
	end,
	KeyBindings = function( self )
		self:ClearMenuItems()
		self:CreateLabel( "Key Binding Options" )
		
		if not self.Keys then self:ExtractKeyBinds() end
		
		local keynames = {}
		for keyname, value in pairs( self.Keys ) do
			for k,v in pairs( keys ) do
				if value == v then
					keynames[keyname] = k:sub(5)
				end
			end
		end
		
		self:CreateButton( "Up (" .. keynames.Up .. ")", function( self ) self:AskForKeyBind( "Up" ) end, 100 )
		self:CreateButton( "Down (" .. keynames.Down .. ")", function( self ) self:AskForKeyBind( "Down" ) end, 100 )
		self:CreateButton( "Left (" .. keynames.Left .. ")", function( self ) self:AskForKeyBind( "Left" ) end, 100 )
		self:CreateButton( "Right (" .. keynames.Right .. ")", function( self ) self:AskForKeyBind( "Right" ) end, 100 )
		self:CreateButton( "A/Shoot (" .. keynames.A .. ")", function( self ) self:AskForKeyBind( "A" ) end, 100 )
		self:CreateButton( "B (" .. keynames.B .. ")", function( self ) self:AskForKeyBind( "B" ) end, 100 )
		self:CreateButton( "Start (" .. keynames.Start .. ")", function( self ) self:AskForKeyBind( "Start" ) end, 100 )
		self:CreateButton( "Select (" .. keynames.Select .. ")", function( self ) self:AskForKeyBind( "Select" ) end, 100 )		
		
		self:CreateButton( "Back", function( self ) self:LoadMenu( "Main" ) end, 100 )
	end,
	ScreenSize = function( self )
		self:ClearMenuItems()
		self:CreateLabel( "Screen Size Options" )
		
		self:CreateButton( "Small", function( self ) RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "1" ) end, 128 )
		self:CreateButton( "Medium (Standard)", function( self ) RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "2" ) end, 128 )
		self:CreateButton( "Large", function( self ) RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "3" ) end, 128 )
		self:CreateButton( "Huge", function( self ) RunConsoleCommand( "gem_emulator_changemodel", self:EntIndex(), "4" ) end, 128 )
							
		self:CreateButton( "Back", function( self ) self:LoadMenu( "Main" ) end, 128 )
	end,
}
function ENT:LoadMenu( str_menu ) 
	local menufunc = menus[str_menu]
	if menufunc then
	
		-- temporary
		local ok, msg = pcall( menufunc, self )
		if not ok then
			self:Error( msg )
		end
		
		--menufunc( self )
	else
		self:Error( "Invalid menu to LoadMenu function: '" .. str_menu .. "'" )
	end
end

----------------------------------------------------------------------
-- Name: Think
-- Desc: Handles the touch screen among other things
----------------------------------------------------------------------
function ENT:Think()
	if not self:GetPly() then return end -- Wait until the owner has been transferred
	if not self.HasMenuItems and self.Emulator then self.Emulator:Think() end
	
	if self:GetPly() ~= LocalPlayer() then return end -- Only do below actions for the owner of the screen
	
	if self.Emulator and not self.HasMenuItems then
		if not self.Keys then
			self:ExtractKeyBinds()
		end
		
		for k,v in pairs( self.Keys ) do
			if input.IsKeyDown( v ) and not self.KeyPresses[k] then
				if k == "Exit" then continue end
				self.Emulator:KeyChanged( k, true )
				self.KeyPresses[k] = true
			elseif self.KeyPresses[k] and not input.IsKeyDown( v ) then
				if k == "Exit" then continue end
				self.Emulator:KeyChanged( k, false )
				self.KeyPresses[k] = nil
			end
		end
		
	else
	
	--if not self.Emulator or self.errordata then

		if not self.Pressing then
			if self.HasMenuItems then
				local x, y = self:GetCursor()
				if x and y then
					if self:GetPly():KeyDown( IN_USE ) then
						self.Pressing = true
					end

					for i=1,#self.MenuItems do
						local item = self.MenuItems[i]
						if not item then break end
						
						if item.type == "button" then
							if inrange( x, y, item.x, item.y, item.x + item.w, item.y + item.h ) then
								item.hover = true
								
								if not item.pressed and self.Pressing then
									item.pressed = true
									
									local t = self.MenuItems
									local ok, msg = pcall( item.onPress, self )
									if not ok then
										self:Error( msg )
									end
									if t ~= self.MenuItems then break end
								end
							else
								item.hover = false
							end
							
							if item.pressed and not self:GetPly():KeyDown( IN_USE ) then
								item.pressed = nil
								
								if item.onRelease then
									local ok, msg = pcall( item.onRelease, self )
									if not ok then
										self:Error( msg )
									end
								end
							end
						end
					end
				end
			end
		elseif self.Pressing and not self:GetPly():KeyDown( IN_USE ) then
			self.Pressing = nil
		end
	
	end
	
	self:NextThink( CurTime() )
	return true
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- Emulator control functions
--------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: GEM_Start
-- Desc: -
----------------------------------------------------------------------
function ENT:LoadROM( curfile, filetype ) 	
	local data = file.Read( curfile )
	self:Enter()
	self.Emulator = gem.New( self, data, filetype )
	
	self:ClearMenuItems()
end

----------------------------------------------------------------------
-- Name: FinalizeROM
-- Desc: -
----------------------------------------------------------------------
function ENT:FinalizeROM() 
	if self.Emulator then
		self.Emulator:OnRemove()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------
-- Key bindings
--------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: ExtractKeyBinds
-- Desc: Load key bindings
----------------------------------------------------------------------
function ENT:ExtractKeyBinds()
	self.Keys = {}
	self.KeyPresses = {}
	
	if not file.IsDir( "gem_emulator" ) or not file.Exists( "gem_emulator/keybinds.txt" ) then
		self.Keys.A 		= KEY_H
		self.Keys.B 		= KEY_J
		self.Keys.Start 	= KEY_ENTER
		self.Keys.Select 	= KEY_LSHIFT
		self.Keys.Up 		= KEY_W
		self.Keys.Left 		= KEY_A
		self.Keys.Down 		= KEY_S
		self.Keys.Right 	= KEY_D
		self.Keys.Exit		= KEY_LALT
		self:SaveKeyBinds()
		return
	end
	
	local lines = string.Explode( "\n", file.Read( "gem_emulator/keybinds.txt" ) )
	for k,v in pairs( lines ) do
		local key, enum = v:match( "(.+)=(.+)" )
		if validKeys[key] and tonumber(enum) ~= nil then
			self.Keys[key] = tonumber(enum)
		end
	end
end

----------------------------------------------------------------------
-- Name: SaveKeyBinds
-- Desc: Save key bindings
----------------------------------------------------------------------
function ENT:SaveKeyBinds()
	if not self.Keys then return end
	file.Write( "gem_emulator/keybinds.txt", string.format( "A=%s\nB=%s\nStart=%s\nSelect=%s\nUp=%s\nLeft=%s\nDown=%s\nRight=%s\nExit=%s", self.Keys.A, self.Keys.B, self.Keys.Start, self.Keys.Select, self.Keys.Up
																																			, self.Keys.Left, self.Keys.Down, self.Keys.Right, self.Keys.Exit ) )
end


----------------------------------------------------------------------
-- Name: AskForKeyBind
-- Desc: Function called by the key bind buttons in the bind options menu
----------------------------------------------------------------------
function ENT:AskForKeyBind( key )
	self:CreateTextEntry( function( code )
		self.Keys[key] = code
		self:RemoveTextEntry()
		self:LoadMenu( "KeyBindings" )
		self:SaveKeyBinds()
	end )
end


----------------------------------------------------------------------
----------------------------------------------------------------------
-- Entity Helper Functions
----------------------------------------------------------------------
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Name: GetCursor
-- Desc: Returns the 2D position of the cursor on the screen
----------------------------------------------------------------------
local aabb_sizes = { 	["models/hunter/plates/plate1x1.mdl"] = 47.45,
						["models/hunter/plates/plate2x2.mdl"] = 94.9,
						["models/hunter/plates/plate3x3.mdl"] = 142.35,
						["models/hunter/plates/plate4x4.mdl"] = 189.8,
					}

function ENT:GetCursor()
	local draw_data = draw_positions[self:GetModel()]
	if not draw_data then return end
	
	local trace = self:GetPly():GetEyeTrace()
	if trace.Entity ~= self or trace.HitPos:Distance( self:GetPly():GetShootPos() ) > 200 then return end
	
	local HitPos = self:WorldToLocal( trace.HitPos ) - draw_data[1]
	
	local size = aabb_sizes[self:GetModel()]
	
	local x = HitPos.y / size * 256 -- * (w2-w) * draw_data[3]-- / 24.15 * 256
	local y = HitPos.x / size * 256-- * (h2-h) * draw_data[3]-- / 24.15 * 256
	return x, y
end

----------------------------------------------------------------------
-- Name: Create/RemoveTextEntry
-- Desc: Creates/Removes the text entry for input
----------------------------------------------------------------------
function ENT:CreateTextEntry( OnChanged )
	if self.Panel and self.Panel:IsValid() then self.Panel:Remove() end
	
	self.Panel = vgui.Create( "DFrame" )
	self.Panel:SetSize( 1,1 )
	self.Panel:SetPos( 50, 50 )
		
	local txt = vgui.Create( "DTextEntry", self.Panel )
	txt:SetEnabled( true )
	txt:SetEditable( true )
	txt:SetSize( 1,1 )
	
	OnChanged = OnChanged or function() end
	txt.OnKeyCodeTyped = function( pnl, code )
		if code == 81 then
			self:Exit()
			return
		end
		OnChanged( code )
	end
	txt.OnTextChanged = function( pnl, txt )
		pnl:SetText( "" )
	end
	
	function txt:OnLoseFocus() self:RequestFocus() end
	
	self.Panel:MakePopup()
	txt:RequestFocus()
end

function ENT:RemoveTextEntry()
	if self.Panel and self.Panel:IsValid() then
		self.Panel:Remove()
	end
	self.Panel = nil
end