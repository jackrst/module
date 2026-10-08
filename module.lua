local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = (function()
	local LocalPlayer = Players.LocalPlayer or (function()
		repeat task.wait() until Players.LocalPlayer
		return Players.LocalPlayer
	end)()
	return LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MenuScreenGui", 9e9) and LocalPlayer
end)()

-- Rejoin helper: teleports back into the same server instead of kicking
local function RejoinGame(reason)
	-- Prevent double-rejoin loops
	if getgenv().ns__PhantomWare__Rejoining then
		return
	end
	getgenv().ns__PhantomWare__Rejoining = true
	getgenv().ns__PhantomWare__Executed = false

	-- Try to notify the user (some executors support this, some don't)
	pcall(function()
		if StarterGui and StarterGui.SetCore and StarterGui:FindFirstChild("RobloxPromptGui") then
			-- Ignored - just try notify
		end
	end)
	warn("[PhantomWare] Rejoining server: " .. tostring(reason))

	-- Give a moment so the warn is visible / cleanup can run
	task.wait(0.5)

	-- Attempt same-server rejoin; if that fails, fall back to a fresh server
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
	if not ok then
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end
end

local Method, ns__require = "Unknown", nil
if typeof(getrenv or get_renv) == "function" then
	local Success, Environment = pcall(getrenv or get_renv)
	ns__require = Success and Environment.shared and Environment.shared.require
	Method = "shared.require"
end

local ModuleCache, ExecutorName = nil, identifyexecutor and identifyexecutor() or (getexecutorname and getexecutorname())
if typeof(ns__require) ~= "function" then
	local ns__Count = 0
	while true do
		if ns__Count >= 10 then
			break
		end

		local ReplicationInterface = ModuleCache and ModuleCache.ReplicationInterface
		if ReplicationInterface and ReplicationInterface.operateOnAllEntries then
			break
		end

		for _,Value in next, (getgc or get_gc)(true) do
			if type(Value) == "table" and rawget(Value, "ScreenCull") and rawget(Value, "NetworkClient") then
				ModuleCache = {}
				for Name, Data in next, Value do
					ModuleCache[Name] = type(Data) == "table" and Data.module or Data
				end
			end
		end

		ns__Count += 1
		task.wait(0.5)
	end

	if not ModuleCache then
		RejoinGame("Module cache not found")
		return nil
	end

	ns__require = function(Name)
		return ModuleCache[Name]
	end

	Method = "fenv.getgc"
elseif not ns__require then
	RejoinGame("shared.require not available")
	return nil
end

return {Players = Players, LocalPlayer = LocalPlayer, Method = Method, ExecutorName = ExecutorName, __get = function(Module)
	local function __internal()
		local Success, Result = pcall(ns__require, Module)
		if Success then
			return Result
		end

		if string.find(tostring(Result), "Reciprocal") then
			return
		end

		warn("[PhantomWare] Failed to require module: " .. Module .. " (" .. tostring(Result) .. ")")
		return nil
	end

	local Source = __internal()
	if not Source then
		local StartTime = os.clock()
		while true do
			if os.clock() - StartTime >= 5 then
				RejoinGame("Module timeout: " .. Module)
				break
			end

			Source = __internal()
			if Source then
				break
			end

			task.wait(0.5)
		end
	end
	return Source
end}
