FarmHandler = {}
FarmHandler.__index = FarmHandler

function FarmHandler:new(
    obj_turtleMoveApi,
    table_moveToFarmList,
    table_moveFromFarmList,
    int_farmWidth,
    int_farmHeight,
    table_seedSlots)
    instance = {}
    instance.obj_turtleMoveApi = obj_turtleMoveApi
    instance.table_moveToFarmList = table_moveToFarmList
    instance.table_moveFromFarmList = table_moveFromFarmList
    instance.int_farmWidth = int_farmWidth
    instance.int_farmHeight = int_farmHeight
    instance.table_seedSlots = table_seedSlots
    setmetatable(instance, FarmHandler)
    return instance
end

function FarmHandler:int_GetMoveCostsForRun()
    --one to move onto the field after arriving
    neededRange = 1
    neededRange = self.obj_turtleMoveApi:int_CalculateCostOfMoveList(self.table_moveToFarmList)

    neededRange = neededRange + self.obj_turtleMoveApi:int_CalculateCostOfMoveList(self.table_moveFromFarmList)

    --calculate sizeof field
    neededRange = self.int_farmHeight * self.int_farmWidth

    --calculate costs for moving from end of done field to start of field again
    if self.int_farmWidth % 2 == 1 then
        --if we end at the farther away end of the farm, we have to also move back
        neededRange = neededRange + self.int_farmHeight
    end

    neededRange = neededRange + self.int_farmWidth

    --+ 1 to get from the field back in to the start position
    return neededRange + 1
end

function FarmHandler:bool_HasEnoughFuelForRun()
    maxRange = self.obj_turtleMoveApi:int_getMoveRange()
    return maxRange >= self:int_GetMoveCostsForRun()
end

function FarmHandler:bool_DoRun()
    if (not self:bool_HasEnoughFuelForRun()) then
        return false
    end
    moveResult = self.obj_turtleMoveApi:int_ExecuteMoveTable(self.table_moveToFarmList)
    if moveResult ~= 0 then
        print("Move to farm failed:")
        print(self.obj_turtleMoveApi:ConvertExecuteMovelistReturnCodeToString(moveResult))
    end
    --we assume, now that we are in front the farm and the
    --next forward step will move us onto the first field of the field
    return self:bool_FarmField()
end

function FarmHandler:bool_FarmField()
    bool_turnRight = true
    --just to move onto the field
    self.obj_turtleMoveApi:bool_MoveForward(1)

    for i = 0, self.int_farmWidth - 1 do
        if (not self.obj_turtleMoveApi:bool_MoveForward(self.int_farmHeight - 1, nil)) then
            return false
        end
        --transition to the next column
        if (i < self.int_farmWidth - 1) then
            if (bool_turnRight) then
                if (not self:bool_RightColumnTransistion()) then
                    print("FALSE")
                    return false
                end
            else
                if (not self:bool_LeftColumnTransistion()) then
                    return false
                end
            end
            bool_turnRight = not bool_turnRight
        end
    end

    if self.int_farmWidth % 2 == 1 then
        self.obj_turtleMoveApi:bool_TurnRight(2,nil)
        self.obj_turtleMoveApi:bool_MoveForward(self.int_farmHeight - 1)
    end
    self.obj_turtleMoveApi:bool_TurnRight(1,nil)
    self.obj_turtleMoveApi:bool_MoveForward(self.int_farmWidth - 1)

    self.obj_turtleMoveApi:bool_TurnLeft(1,nil)
    self.obj_turtleMoveApi:bool_MoveForward(1)
    self.obj_turtleMoveApi:bool_TurnLeft(2,nil)
end

function FarmHandler:bool_FarmSingleField()
    seedSlot = self:int_GetNextValidSeedSlot()
    if (seedSlot == -1) then
        return false
    end

    turtle.digDown()
    selectedSlot = turtle.getSelectedSlot()
    turtle.select(seedSlot)
    turtle.placeDown()
    turtle.select(selectedSlot)
end

function FarmHandler:int_GetNextValidSeedSlot()
    for index, slotNum in ipairs(self.table_seedSlots) do
        if (turtle.getItemCount(slotNum) > 2) then
            return slotNum
        end
    end
    return -1
end

function FarmHandler:bool_RightColumnTransistion()
    if (not self.obj_turtleMoveApi:bool_TurnRight(1, nil)) then
        return false
    end
    if (not self.obj_turtleMoveApi:bool_MoveForward(1, nil)) then
        return false
    end
    if (not self.obj_turtleMoveApi:bool_TurnRight(1, nil)) then
        return false
    end
    return true
end

function FarmHandler:bool_LeftColumnTransistion()
    if (not self.obj_turtleMoveApi:bool_TurnLeft(1, nil)) then
        return false
    end
    if (not self.obj_turtleMoveApi:bool_MoveForward(1, nil)) then
        return false
    end
    if (not self.obj_turtleMoveApi:bool_TurnLeft(1, nil)) then
        return false
    end
    return true
end