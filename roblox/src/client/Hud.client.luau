--!strict
-- HUD: regalos en el saco, monedas, ayuda de controles y lo que llevas en las manos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("GameState") :: Folder

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function text(name: string, position: UDim2, size: UDim2, anchor: Vector2, fontSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.AnchorPoint = anchor
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = fontSize
	label.TextColor3 = Color3.fromRGB(255, 235, 170)
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return label
end

local counter = text("Contador", UDim2.new(0.5, 0, 0, 8), UDim2.new(0.8, 0, 0, 40), Vector2.new(0.5, 0), 30)
local held = text("Mano", UDim2.new(0.5, 0, 1, -90), UDim2.new(0.8, 0, 0, 30), Vector2.new(0.5, 1), 22)
held.TextColor3 = Color3.new(1, 1, 1)
local help = text("Ayuda", UDim2.new(0, 12, 0, 56), UDim2.new(0, 420, 0, 60), Vector2.zero, 16)
help.TextColor3 = Color3.new(1, 1, 1)
help.TextXAlignment = Enum.TextXAlignment.Left
help.TextYAlignment = Enum.TextYAlignment.Top
help.Text = "TALLER DE ELFOS\nMadera → fábrica → mesa de envolver → saco de Santa\n[E] coger/soltar/usar · [F] envolver · [Clic] lanzar"
help.Visible = not UserInputService.TouchEnabled

-- Punto de mira en el centro para saber hacia dónde lanzas.
local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(6, 6)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = Color3.new(1, 1, 1)
dot.BorderSizePixel = 0
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = dot
dot.Parent = gui

local function refresh()
	local gifts = state:GetAttribute("Gifts") :: number
	local goal = state:GetAttribute("Goal") :: number
	local money = state:GetAttribute("Money") :: number
	counter.Text = string.format("Saco: %d / %d      Monedas: %d", gifts, goal, money)
	if gifts >= goal then
		counter.Text ..= "      ¡Saco lleno!"
	end
	local holding = player:GetAttribute("Holding") :: string?
	held.Text = if holding then string.format("Llevas: %s · %s", holding, if UserInputService.TouchEnabled then "Soltar / Lanzar" else "[E] soltar · [Clic] lanzar") else ""
end

for _, name in { "Gifts", "Goal", "Money" } do
	state:GetAttributeChangedSignal(name):Connect(refresh)
end
player:GetAttributeChangedSignal("Holding"):Connect(refresh)
refresh()
