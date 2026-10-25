--!strict
-- Controles del elfo propio para lo que no hacen los ProximityPrompts:
-- [E] suelta lo que llevas, [Clic izquierdo] lo lanza hacia donde miras.
-- En móvil salen dos botones en pantalla. Mientras llevas algo se apagan los prompts,
-- así [E] no coge otra cosa ni usa una estación sin querer.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local release = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Release") :: RemoteEvent
local items = workspace:WaitForChild("Items")

local holding: BasePart? = nil

local function lookDirection(): Vector3
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.LookVector else Vector3.new(0, 0, -1)
end

local function onDrop(_name: string, inputState: Enum.UserInputState): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin and holding then
		local dir = lookDirection()
		release:FireServer(false, Vector3.new(dir.X, 0, dir.Z))
	end
	return Enum.ContextActionResult.Sink
end

local function onThrow(_name: string, inputState: Enum.UserInputState): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin and holding then
		release:FireServer(true, lookDirection())
	end
	return Enum.ContextActionResult.Sink
end

local function setHolding(item: BasePart?)
	if item == holding then
		return
	end
	holding = item
	ProximityPromptService.Enabled = item == nil
	if item then
		ContextActionService:BindAction("ElfoSoltar", onDrop, true, Enum.KeyCode.E, Enum.KeyCode.ButtonB)
		ContextActionService:BindAction("ElfoLanzar", onThrow, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
		ContextActionService:SetTitle("ElfoSoltar", "Soltar")
		ContextActionService:SetTitle("ElfoLanzar", "Lanzar")
	else
		ContextActionService:UnbindAction("ElfoSoltar")
		ContextActionService:UnbindAction("ElfoLanzar")
	end
	player:SetAttribute("Holding", if item then item.Name else nil)
end

local function check(item: Instance)
	if not item:IsA("BasePart") then
		return
	end
	if item:GetAttribute("Holder") == player.UserId then
		setHolding(item)
	elseif holding == item then
		setHolding(nil)
	end
end

local function watch(item: Instance)
	check(item)
	item:GetAttributeChangedSignal("Holder"):Connect(function()
		check(item)
	end)
end

for _, item in items:GetChildren() do
	watch(item)
end
items.ChildAdded:Connect(watch)
items.ChildRemoved:Connect(function(item)
	if item == holding then
		setHolding(nil)
	end
end)
