--!strict
-- Ayudas para montar el mapa con piezas desde código (como MeshKit en Godot).

local Build = {}

export type PartProps = {
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	shape: Enum.PartType?,
	anchored: boolean?,
	collide: boolean?,
	transparency: number?,
	name: string?,
}

function Build.part(parent: Instance, props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color or Color3.fromRGB(160, 110, 70)
	p.Material = props.material or Enum.Material.SmoothPlastic
	if props.shape then
		p.Shape = props.shape
	end
	p.Anchored = if props.anchored == nil then true else props.anchored
	p.CanCollide = if props.collide == nil then true else props.collide
	p.Transparency = props.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Pieza de adorno: no choca, no se puede tocar ni detectar con rayos.
function Build.deco(parent: Instance, props: PartProps): Part
	props.collide = false
	local p = Build.part(parent, props)
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = props.transparency == nil or props.transparency < 0.5
	return p
end

-- Zona invisible para detectar objetos (bocas de máquinas, saco...).
function Build.zone(parent: Instance, name: string, size: Vector3, cframe: CFrame): Part
	local p = Build.part(parent, { name = name, size = size, cframe = cframe, collide = false, transparency = 1 })
	p.CanTouch = false
	p.CanQuery = false
	return p
end

-- Suelda las piezas de adorno de un objeto suelto a su pieza principal.
function Build.weldTo(root: BasePart, piece: BasePart)
	piece.Anchored = false
	piece.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = piece
	weld.Parent = piece
end

-- Cartel flotante encima de algo. Devuelve el TextLabel para cambiar el texto.
function Build.label(adornee: BasePart, text: string, height: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	gui.Parent = adornee
	return label
end

function Build.light(parent: BasePart, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = true
	light.Parent = parent
end

return Build
