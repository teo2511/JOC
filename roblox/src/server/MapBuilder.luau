--!strict
-- Construye el mapa al arrancar el servidor: taller de madera con tejado nevado, patio con
-- nieve, valla, bosque alrededor, faroles, guirnaldas, árbol de Navidad y nieve cayendo.
-- Las medidas siguen la versión de Godot (1 m = 3,5 studs): taller de 105 x 105 studs.

local Lighting = game:GetService("Lighting")

local Build = require(script.Parent.Build)

local MapBuilder = {}

local HALF = 52.5 -- media anchura del taller
local WALL_H = 12
local RIDGE_H = 24
local DOOR_W = 16
local YARD_X0, YARD_X1 = HALF, HALF + 105 -- el patio queda al este del taller

local WOOD = Color3.fromRGB(150, 98, 58)
local WOOD_DARK = Color3.fromRGB(78, 46, 28)
local SNOW = Color3.fromRGB(235, 240, 250)
local WARM = Color3.fromRGB(255, 200, 130)

local function setupLighting()
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.35
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(70, 85, 130)
	atmosphere.Decay = Color3.fromRGB(30, 35, 70)
	atmosphere.Glare = 0
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.2
	bloom.Parent = Lighting
	local color = Instance.new("ColorCorrectionEffect")
	color.TintColor = Color3.fromRGB(235, 238, 255)
	color.Saturation = 0.1
	color.Parent = Lighting
end

local function lantern(parent: Instance, position: Vector3, hanging: boolean)
	local glass = Build.deco(parent, {
		name = "Farol",
		size = Vector3.new(1.1, 1.3, 1.1),
		cframe = CFrame.new(position),
		color = WARM,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
	})
	Build.light(glass, WARM, 1.6, 40)
	local iron = Color3.fromRGB(25, 25, 28)
	Build.deco(parent, {
		size = Vector3.new(0.4, 1.4, 1.4),
		cframe = CFrame.new(position + Vector3.new(0, 0.85, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = iron,
		material = Enum.Material.Metal,
		shape = Enum.PartType.Cylinder,
	})
	if hanging then
		local top = WALL_H + 1
		local length = top - position.Y - 1.5
		Build.deco(parent, {
			size = Vector3.new(0.15, length, 0.15),
			cframe = CFrame.new(position + Vector3.new(0, 1.5 + length / 2, 0)),
			color = iron,
		})
	else
		Build.deco(parent, {
			size = Vector3.new(position.Y - 0.6, 0.5, 0.5),
			cframe = CFrame.new(position.X, (position.Y - 0.6) / 2, position.Z) * CFrame.Angles(0, 0, math.rad(90)),
			color = iron,
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
		})
	end
end

-- Guirnalda de bombillas de colores entre dos puntos, con una pequeña caída.
local function stringLights(parent: Instance, from: Vector3, to: Vector3, sag: number)
	local colors = {
		Color3.fromRGB(255, 60, 50),
		Color3.fromRGB(60, 230, 90),
		Color3.fromRGB(255, 205, 60),
		Color3.fromRGB(80, 130, 255),
	}
	local count = math.max(math.floor((to - from).Magnitude / 2.5), 2)
	for i = 0, count do
		local f = i / count
		local pos = from:Lerp(to, f) - Vector3.new(0, sag * 4 * f * (1 - f), 0)
		Build.deco(parent, {
			size = Vector3.new(0.5, 0.5, 0.5),
			cframe = CFrame.new(pos),
			color = colors[(i % #colors) + 1],
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
		})
	end
end

-- Abeto de pisos con nieve encima. scale 1 = unos 16 studs de alto.
local function pine(parent: Instance, base: Vector3, scale: number, decorated: boolean)
	Build.deco(parent, {
		size = Vector3.new(3 * scale, 1.6 * scale, 1.6 * scale),
		cframe = CFrame.new(base + Vector3.new(0, 1.5 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color = Color3.fromRGB(75, 45, 25),
		material = Enum.Material.Wood,
		shape = Enum.PartType.Cylinder,
	})
	local tiers = 5
	for i = 0, tiers - 1 do
		local r = (9 - i * 1.6) * scale
		local y = (3 + i * 2.6) * scale
		Build.deco(parent, {
			size = Vector3.new(2.2 * scale, r, r),
			cframe = CFrame.new(base + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			color = Color3.fromRGB(22, 75, 45),
			material = Enum.Material.Grass,
			shape = Enum.PartType.Cylinder,
		})
		Build.deco(parent, {
			size = Vector3.new(0.5 * scale, r * 0.75, r * 0.75),
			cframe = CFrame.new(base + Vector3.new(0, y + 1.25 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			color = SNOW,
			material = Enum.Material.Snow,
			shape = Enum.PartType.Cylinder,
		})
		if decorated then
			for k = 1, 5 do
				local angle = k / 5 * math.pi * 2 + i
				local ball = Build.deco(parent, {
					size = Vector3.new(0.9, 0.9, 0.9),
					cframe = CFrame.new(base + Vector3.new(math.cos(angle) * r * 0.48, y - 0.6 * scale, math.sin(angle) * r * 0.48)),
					color = if k % 2 == 0 then Color3.fromRGB(230, 40, 40) else Color3.fromRGB(255, 200, 60),
					material = Enum.Material.Neon,
					shape = Enum.PartType.Ball,
				})
				ball.CastShadow = false
			end
		end
	end
	if decorated then
		local star = Build.deco(parent, {
			size = Vector3.new(1.8, 1.8, 1.8),
			cframe = CFrame.new(base + Vector3.new(0, (3 + tiers * 2.6) * scale, 0)) * CFrame.Angles(0, 0, math.rad(45)),
			color = Color3.fromRGB(255, 215, 80),
			material = Enum.Material.Neon,
		})
		Build.light(star, Color3.fromRGB(255, 210, 120), 1, 20)
	end
end

local function window(parent: Instance, cframe: CFrame)
	-- cframe mira hacia fuera de la pared (LookVector).
	Build.deco(parent, {
		size = Vector3.new(5, 4, 0.2),
		cframe = cframe,
		color = Color3.fromRGB(70, 100, 170),
		material = Enum.Material.Neon,
		transparency = 0.35,
	})
	for _, piece in { { Vector3.new(5.6, 0.4, 0.5), Vector3.new(0, 2.1, 0) }, { Vector3.new(6, 0.6, 0.9), Vector3.new(0, -2.2, 0) }, { Vector3.new(0.4, 4.6, 0.5), Vector3.new(-2.7, 0, 0) }, { Vector3.new(0.4, 4.6, 0.5), Vector3.new(2.7, 0, 0) }, { Vector3.new(0.25, 4, 0.4), Vector3.zero }, { Vector3.new(5, 0.25, 0.4), Vector3.zero } } do
		Build.deco(parent, { size = piece[1], cframe = cframe * CFrame.new(piece[2]), color = WOOD_DARK, material = Enum.Material.Wood })
	end
	Build.deco(parent, { size = Vector3.new(5.6, 0.3, 0.8), cframe = cframe * CFrame.new(0, -1.85, 0), color = SNOW, material = Enum.Material.Snow })
end

local function buildWorkshop(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Taller"
	folder.Parent = map

	Build.part(folder, {
		name = "Suelo",
		size = Vector3.new(HALF * 2, 2, HALF * 2),
		cframe = CFrame.new(0, -1, 0),
		color = Color3.fromRGB(120, 76, 44),
		material = Enum.Material.WoodPlanks,
	})
	local wall = { color = WOOD, material = Enum.Material.WoodPlanks }
	local t = 2
	local walls = {
		{ Vector3.new(HALF * 2, WALL_H, t), Vector3.new(0, WALL_H / 2, -HALF) },
		{ Vector3.new(HALF * 2, WALL_H, t), Vector3.new(0, WALL_H / 2, HALF) },
		{ Vector3.new(t, WALL_H, HALF * 2), Vector3.new(-HALF, WALL_H / 2, 0) },
		{ Vector3.new(t, WALL_H, HALF - DOOR_W / 2), Vector3.new(HALF, WALL_H / 2, -(HALF + DOOR_W / 2) / 2) },
		{ Vector3.new(t, WALL_H, HALF - DOOR_W / 2), Vector3.new(HALF, WALL_H / 2, (HALF + DOOR_W / 2) / 2) },
	}
	for _, w in walls do
		Build.part(folder, { name = "Pared", size = w[1], cframe = CFrame.new(w[2]), color = wall.color, material = wall.material })
	end
	-- Zócalo oscuro, postes y viga de remate.
	for _, w in walls do
		Build.deco(folder, {
			size = Vector3.new(w[1].X + 0.3, 1.4, w[1].Z + 0.3),
			cframe = CFrame.new(w[2].X, 0.7, w[2].Z),
			color = WOOD_DARK,
			material = Enum.Material.Wood,
		})
	end
	for i = 0, 4 do
		local s = -HALF + i * HALF / 2
		local posts = { Vector3.new(s, 0, -HALF), Vector3.new(s, 0, HALF), Vector3.new(-HALF, 0, s) }
		if math.abs(s) > DOOR_W / 2 then
			table.insert(posts, Vector3.new(HALF, 0, s))
		end
		for _, p in posts do
			Build.deco(folder, { size = Vector3.new(2.4, WALL_H + 1, 2.4), cframe = CFrame.new(p.X, (WALL_H + 1) / 2, p.Z), color = WOOD_DARK, material = Enum.Material.Wood })
		end
	end
	for _, z in { -DOOR_W / 2, DOOR_W / 2 } do
		Build.deco(folder, { size = Vector3.new(2.4, WALL_H + 1, 2.4), cframe = CFrame.new(HALF, (WALL_H + 1) / 2, z), color = WOOD_DARK, material = Enum.Material.Wood })
	end

	-- Tejado a dos aguas (cumbrera a lo largo de X) con nieve encima, vigas por dentro.
	local span = HALF + 3
	local rise = RIDGE_H - WALL_H
	local slope = math.atan2(rise, span)
	local length = math.sqrt(span * span + rise * rise)
	for _, side in { -1, 1 } do
		local cf = CFrame.new(0, WALL_H + rise / 2 + 0.5, side * span / 2) * CFrame.Angles(side * slope, 0, 0)
		Build.part(folder, { name = "Tejado", size = Vector3.new(HALF * 2 + 6, 1, length), cframe = cf, color = Color3.fromRGB(95, 40, 32), material = Enum.Material.Slate })
		Build.deco(folder, { size = Vector3.new(HALF * 2 + 6.4, 0.8, length + 0.3), cframe = cf * CFrame.new(0, 0.85, 0), color = SNOW, material = Enum.Material.Snow })
	end
	for _, x in { -HALF, HALF } do
		local gable = Instance.new("WedgePart")
		-- Dos cuñas forman el triángulo de cada hastial.
		for _, side in { -1, 1 } do
			local wedge = gable:Clone()
			wedge.Size = Vector3.new(t, rise, span - 3)
			wedge.CFrame = CFrame.new(x, WALL_H + rise / 2, side * (span - 3) / 2) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0) -- lo alto de la cuña, en la cumbrera
			wedge.Color = WOOD
			wedge.Material = Enum.Material.WoodPlanks
			wedge.Anchored = true
			wedge.Parent = folder
		end
		gable:Destroy()
	end
	for i = 0, 5 do
		local x = -HALF + 8.75 + i * 17.5
		Build.deco(folder, { size = Vector3.new(1.4, 1.6, HALF * 2), cframe = CFrame.new(x, WALL_H + 0.8, 0), color = WOOD_DARK, material = Enum.Material.Wood })
		Build.deco(folder, { size = Vector3.new(1.2, rise - 1, 1.2), cframe = CFrame.new(x, WALL_H + 1 + (rise - 1) / 2, 0), color = WOOD_DARK, material = Enum.Material.Wood })
	end
	Build.deco(folder, { size = Vector3.new(HALF * 2, 1.4, 1.2), cframe = CFrame.new(0, RIDGE_H - 0.8, 0), color = WOOD_DARK, material = Enum.Material.Wood })

	-- Ventanas, faroles colgados y guirnaldas.
	for _, x in { -31.5, -3.5, 24.5 } do
		window(folder, CFrame.new(x, 6.5, -HALF + 1.15))
		window(folder, CFrame.new(x, 6.5, HALF - 1.15) * CFrame.Angles(0, math.pi, 0))
	end
	for _, z in { -30, 30 } do
		window(folder, CFrame.new(HALF - 1.15, 6.5, z) * CFrame.Angles(0, -math.pi / 2, 0))
		window(folder, CFrame.new(HALF + 1.15, 6.5, z) * CFrame.Angles(0, math.pi / 2, 0))
	end
	for _, p in { Vector3.new(-26, 9, -31), Vector3.new(9, 9, -31), Vector3.new(-26, 9, 17), Vector3.new(26, 9, 17) } do
		lantern(folder, p, true)
	end
	stringLights(folder, Vector3.new(-HALF + 1.5, WALL_H - 1, -HALF + 1.6), Vector3.new(HALF - 1.5, WALL_H - 1, -HALF + 1.6), 1.2)
	stringLights(folder, Vector3.new(-HALF + 1.5, WALL_H - 1, HALF - 1.6), Vector3.new(HALF - 1.5, WALL_H - 1, HALF - 1.6), 1.2)
	stringLights(folder, Vector3.new(HALF - 1.6, WALL_H - 1.2, -DOOR_W / 2), Vector3.new(HALF - 1.6, WALL_H - 1.2, DOOR_W / 2), 1.5)
	pine(folder, Vector3.new(40, 0, -40), 0.7, true)

	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(0, 0.2, 10)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
end

local function buildOutside(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Exterior"
	folder.Parent = map

	-- Patio con nieve (aquí irán las casas y el trineo en la fase R3).
	Build.part(folder, {
		name = "Patio",
		size = Vector3.new(YARD_X1 - YARD_X0, 2, HALF * 2),
		cframe = CFrame.new((YARD_X0 + YARD_X1) / 2, -1, 0),
		color = SNOW,
		material = Enum.Material.Snow,
	})
	local fence = Color3.fromRGB(150, 50, 40)
	local yardMid = (YARD_X0 + YARD_X1) / 2
	local yardLen = YARD_X1 - YARD_X0
	for _, f in { { Vector3.new(yardLen, 7, 1.4), Vector3.new(yardMid, 3.5, -HALF) }, { Vector3.new(yardLen, 7, 1.4), Vector3.new(yardMid, 3.5, HALF) }, { Vector3.new(1.4, 7, HALF * 2), Vector3.new(YARD_X1, 3.5, 0) } } do
		Build.part(folder, { name = "Valla", size = f[1], cframe = CFrame.new(f[2]), color = fence, material = Enum.Material.WoodPlanks })
		Build.deco(folder, { size = f[1] + Vector3.new(0.3, -6.5, 0.6), cframe = CFrame.new(f[2] + Vector3.new(0, 3.6, 0)), color = SNOW, material = Enum.Material.Snow })
	end
	lantern(folder, Vector3.new(YARD_X0 + 24, 12, 0), false)
	lantern(folder, Vector3.new(YARD_X1 - 24, 12, 0), false)
	pine(folder, Vector3.new(yardMid, 0, 0), 1.0, true)

	-- Llanura nevada y bosque alrededor (sin colisión fuera de la zona de juego).
	local center = Vector3.new((-HALF + YARD_X1) / 2, 0, 0)
	local ground = Build.deco(folder, {
		size = Vector3.new(1400, 2, 1400),
		cframe = CFrame.new(center.X, -1.2, center.Z),
		color = SNOW,
		material = Enum.Material.Snow,
	})
	ground.CanCollide = true -- por si alguien salta la valla
	local rng = Random.new(2511)
	local placed = 0
	while placed < 160 do
		local p = Vector3.new(center.X + rng:NextNumber(-380, 380), 0, center.Z + rng:NextNumber(-380, 380))
		local inside = p.X > -HALF - 15 and p.X < YARD_X1 + 15 and math.abs(p.Z) < HALF + 15
		if not inside and (p - center).Magnitude < 380 then
			pine(folder, p, rng:NextNumber(0.8, 1.6), false)
			placed += 1
		end
	end

	-- Nieve cayendo sobre el patio.
	local sky = Build.zone(folder, "NieveCayendo", Vector3.new(yardLen + 40, 1, HALF * 2 + 40), CFrame.new(yardMid, 50, 0))
	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.LightEmission = 0.3
	snow.Size = NumberSequence.new(0.35)
	snow.Rate = 120
	snow.Lifetime = NumberRange.new(9, 12)
	snow.Speed = NumberRange.new(4, 6)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.SpreadAngle = Vector2.new(12, 12)
	snow.Acceleration = Vector3.new(1, 0, 0)
	snow.Parent = sky
end

function MapBuilder.build(): Folder
	setupLighting()
	local map = Instance.new("Folder")
	map.Name = "Mapa"
	map.Parent = workspace
	buildWorkshop(map)
	buildOutside(map)
	return map
end

MapBuilder.HALF = HALF
MapBuilder.WALL_H = WALL_H

return MapBuilder
