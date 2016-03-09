class FlankPreviewFlagManager extends UIUnitFlagManager dependson(GotchaUnitFlagHelper);

const VISION_DISTANCE = 100000; //What are these units??
const HACKING_DISTANCE = 107500;

var UISpecialMissionHUD_Arrows ArrowManager;
var GotchaUnitFlagHelper unitFlagHelper;


struct UnitFlagDisplayState
{
    var int StoredObjectID;
    var EUnitVisibilityState unitVState;

    structdefaultproperties
    {
        unitVState = eUVS_NotVisible;
    }
};
var array<UnitFlagDisplayState>	unitStateArr;

// @Override
simulated function AddFlags()
{
	local XComGameState_Unit UnitState;
	local T3DArrow ObjArrow;

    super.AddFlags();

    ArrowManager = UISpecialMissionHUD_Arrows(`PRES.GetSpecialMissionHUD().GetChildByName('arrowContainer'));

	if (bIsInited)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
		{
	        // Add UnitFlag for VIP Bad
			if (UnitState.GetMyTemplateName() == 'HostileVIPCivilian')
			{
				AddFlag(UnitState.GetReference());

				ObjArrow = getArrowObject(`XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation));
				ArrowManager.AddArrowPointingAtActor(UnitState.GetVisualizer(), ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter,
				    class'GotchaUnitFlagHelper'.default.IconSet_Objective_Kill_VIP.defaultIcon);
			}
		}
	}
}

// @Override
simulated function StartTurn()
{
	local XComGameState_Unit UnitState;
    local T3DArrow ObjArrow;

    super.StartTurn();

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
    {
        // Update Arrow for VIP Bad
        // TODO: find method where VIP Bad arrow is replaced with VIPGood
        if (UnitState.GetMyTemplateName() == 'HostileVIPCivilian')
        {
            ObjArrow = getArrowObject(`XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation));
            ArrowManager.AddArrowPointingAtActor(UnitState.GetVisualizer(), ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter,
                class'GotchaUnitFlagHelper'.default.IconSet_Objective_Kill_VIP.defaultIcon);
        }
    }
}

// @Override
function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local XComGameState_Unit SourceUnitState;

    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_lastActiveUnit.ObjectID,,-1));

//    `log("------------------");
//    `log("UNIT = " @ SourceUnitState);

    processUnitsWithHealth(MoveToTileData, SourceUnitState);

    // Some objects do not have corresponding UnitFlag as they don't have health, so we need to search for them explicitly.
	processHackableObjectsWithoutHealth(MoveToTileData.EventTile, SourceUnitState);
}

private function processUnitsWithHealth(GameplayTileData MoveToTileData, XComGameState_Unit SourceUnitState)
{
    local int									Index;
    local UIUnitFlag							kFlag;
    local GameRulesCache_VisibilityInfo			VisibilityInfo;
    local XComGameState_Unit					TargetUnitState;
    local XComGameState_BaseObject				flagObj;
    local XComGameState_Destructible			destructibleObject;
    local XComGameState_InteractiveObject		interactiveObject;
    local T3DArrow								ObjArrow;
    local EUnitVisibilityState                  unitVState;
//    local vector                                testLocation;

    foreach m_arrFlags(kFlag)
    {
        flagObj = `XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID,,-1);
//        `log("kFlag = " @ flagObj);

        ObjArrow = getArrowObject(class'GotchaUnitFlagHelper'.static.getUnitFlagLocation(kFlag));
//        `log("ObjArrow.Icon=" @ObjArrow.Icon);

        TargetUnitState = XComGameState_Unit(flagObj);
        destructibleObject = XComGameState_Destructible(flagObj);
        interactiveObject = XComGameState_InteractiveObject(flagObj);

        // Interactive Objects
        if (interactiveObject != none)
        {
//            `log("interactiveObject=" @ObjArrow.Icon);

            // can see via SquadSight
            if (`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, interactiveObject.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
            {
                if (VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * VISION_DISTANCE))
                {
                    unitVState = eUVS_Spotted;
                }
                else
                {
                    unitVState = SourceUnitState.HasSquadSight() ? eUVS_SquadSight : eUVS_NotVisible;
                }
            }
            else
            {
                unitVState = eUVS_NotVisible;
            }

            SetUnitFlagState(kFlag, unitVState, ObjArrow);
            continue;
        }

        // Enemy Units
        if (TargetUnitState != none && TargetUnitState.IsEnemyUnit(SourceUnitState))
        {
//            `log("TargetUnitState=" @TargetUnitState @", kFlag.StoredObjectID=" @kFlag.StoredObjectID @", template=" @TargetUnitState.GetMyTemplateName());

             if (TargetUnitState.GetMyTemplateName() == 'HostileVIPCivilian' && ObjArrow.icon == "")
             {
                ArrowManager.AddArrowPointingAtActor(TargetUnitState.GetVisualizer(), ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter,
                    class'GotchaUnitFlagHelper'.default.IconSet_Objective_Kill_VIP.defaultIcon);
             }

            Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
            if (Index == INDEX_NONE) // if not visible
            {
                // can see via SquadSight
                if (SourceUnitState.HasSquadSight() && `XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, TargetUnitState.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
                {
                    displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, true, ObjArrow);
                }
                else
                {
                    SetUnitFlagState(kFlag, eUVS_NotVisible, ObjArrow);
                }
            }
            else
            {
                VisibilityInfo = MoveToTileData.VisibleEnemies[Index];
                displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo, false, ObjArrow);
            }
            continue;
        }

        // Destructible Objects (e.g. barrels)
        if (destructibleObject != none)
        {
//            `log("kFlag.destructibleObject=" @destructibleObject);
            continue;
        }
    }
}

private function processHackableObjectsWithoutHealth(TTile eventTile, XComGameState_Unit SourceUnitState)
{
    local GameRulesCache_VisibilityInfo			VisibilityInfo;
    local XComGameState_Destructible			destructibleObject;
    local XComGameState_ObjectiveInfo           objectiveInfo;
    local XComInteractiveLevelActor             objActor;
    local XComGameState_InteractiveObject       actorObjectState;
    local StateObjectReference					EmptyRef;
    local T3DArrow								ObjArrow;
    local vector                                testLocation;

    // Mission: Recover Item from train
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_ObjectiveInfo', objectiveInfo)
    {
        // skip objects that have been already processed by "WithHealth" processor
        destructibleObject = XComGameState_Destructible(`XCOMHISTORY.GetGameStateComponentForObjectID(objectiveInfo.ObjectID, class'XComGameState_Destructible'));
        if (destructibleObject == none || hasUnitFlag(destructibleObject.ObjectID)) continue;

        testLocation = `XWORLD.GetPositionFromTileCoordinates(destructibleObject.TileLocation);
        ObjArrow = getArrowObject(testLocation);
//        `log("HackableObjectWithoutHealth=" @ObjArrow.Icon);

        // display Hack icon only if unit has IntrusionProtocol skill
        if (SourceUnitState.FindAbility('IntrusionProtocol') != EmptyRef)
        {
            `XWORLD.CanSeeTileToTile(eventTile, destructibleObject.TileLocation, VisibilityInfo);

            if (VisibilityInfo.bClearLOS && VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * HACKING_DISTANCE))
            {
                objActor = XComInteractiveLevelActor(objectiveInfo.GetVisualizer());
                actorObjectState = objActor.GetInteractiveState();

                if (actorObjectState.MustBeHacked() && !actorObjectState.HasBeenHacked())
                {
//                    `log("HACKING id=" @destructibleObject.ObjectID);
                    displayArrow(ObjArrow, eUVS_Hacking);
                    continue;
                }
            }
        }

        // clear arrow by default
        displayArrow(ObjArrow, eUVS_NotVisible);
    }
}

private function bool hasUnitFlag(int objectId)
{
    local UIUnitFlag kFlag;

    foreach m_arrFlags(kFlag)
    {
        if (kFlag.StoredObjectID == objectId) return true;
    }
    return false;
}

private function T3DArrow getArrowObject(vector vUnitLoc)
{
    local T3DArrow ObjArrow, ObjArrowNone;
    local vector targetLocation;

    foreach ArrowManager.arr3Darrows(ObjArrow)
    {
        if (ObjArrow.kActor != none)
        {
            targetLocation = ObjArrow.kActor.Location;
        }
        else
        {
            targetLocation = ObjArrow.loc;
        }

//        `log("(" @ vUnitLoc.X @", " @vUnitLoc.Y @") => (" @targetLocation.X @", " @targetLocation.Y @"), icon=" @ ObjArrow.Icon);

        if ((vUnitLoc.X == targetLocation.X && vUnitLoc.Y == targetLocation.Y) || VSizeSq(vUnitLoc - targetLocation) < 0.0001f)
        {
//            `log("FOUND, icon =" @ ObjArrow.icon);
            return ObjArrow;
        }
    }
    return ObjArrowNone;
}

private function displaySpottedIcon(UIUnitFlag kFlag,
                           TTile tile,
                           XComGameState_Unit SourceUnitState,
                           XComGameState_Unit TargetUnitState,
                           GameRulesCache_VisibilityInfo VisibilityInfo,
						   bool squadsight,
						   T3DArrow ObjArrow)
{
    local EUnitVisibilityState unitVState;
    local bool flanked;

    flanked = class'GotchaVisibilityHelper'.static.IsFlankedByLocation(tile, SourceUnitState, TargetUnitState, VisibilityInfo);

    if (flanked && squadsight) unitVState = eUVS_SquadSightFlanked;
    if (flanked && !squadsight) unitVState = eUVS_Flanked;
    if (!flanked && squadsight) unitVState = eUVS_SquadSight;
    if (!flanked && !squadsight) unitVState = eUVS_Spotted;

    SetUnitFlagState(kFlag, unitVState, ObjArrow);
}

private function SetUnitFlagState(UIUnitFlag kFlag,
                                  EUnitVisibilityState unitVState,
                                  T3DArrow ObjArrow)
{
//    `log("SetUnitFlagState ::: kFlag = " @ kFlag.StoredObjectID @", unitVState=" @unitVState);

    if (ObjArrow.icon != "") // objectives
    {
        SetSpottedAndFlankedState(kFlag, eUVS_NotVisible);
        displayArrow(ObjArrow, unitVState);
    }
    else
    {
        SetSpottedAndFlankedState(kFlag, unitVState);
    }
}

private function SetSpottedAndFlankedState(UIUnitFlag kFlag, EUnitVisibilityState unitVState)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool spotted, flanked, squadsight;

	spotted = (unitVState == eUVS_Spotted || unitVState == eUVS_Flanked);
	flanked = (unitVState == eUVS_Flanked || unitVState == eUVS_SquadSightFlanked);
	squadsight = (unitVState == eUVS_SquadSight || unitVState == eUVS_SquadSightFlanked);

    // render flags with new state only
	if (hasSameSate(kFlag, unitVState)) return;

    // save the state
	kFlag.m_bSpotted = spotted;

    // Display crosshair
	myValue.Type = AS_Boolean;
	myValue.b = spotted;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
    myValue.b = flanked;
    myArray.AddItem( myValue );

	kFlag.Invoke("SetSpottedState", myArray);

	// Display squadsight diamond
    if (!squadsight) kFlag.SetAlertState(eUnitFlagAlert_None);
	else if (squadsight && !flanked)    kFlag.SetAlertState(eUnitFlagAlert_Red);
	else if (squadsight && flanked)    kFlag.SetAlertState(eUnitFlagAlert_Yellow);
}

private function bool hasSameSate(UIUnitFlag kFlag, EUnitVisibilityState unitVState)
{
    local UnitFlagDisplayState unitState;
    local int Index, i;

    // Search for UnitFlag
    Index = INDEX_NONE;
    for (i=0; i < unitStateArr.length; i++)
    {
        if (unitStateArr[i].StoredObjectID == kFlag.StoredObjectID)
        {
            Index = i;
            break;
        }
    }

    // create and new unit state if it has not been saved before
    if (Index == INDEX_NONE)
    {
        unitState.StoredObjectID = kFlag.StoredObjectID;
        unitState.unitVState = unitVState;

        unitStateArr.addItem(unitState);
        return false;
    }

    unitState = unitStateArr[Index];

    // do nothing if state is the same
    if (unitState.unitVState == unitVState)
    {
        return true;
    }

    // save the new state
    unitStateArr[Index].unitVState = unitVState;

    return false;
}

private function displayArrow(T3DArrow ObjArrow, EUnitVisibilityState unitVState)
{
	local string arrowIcon;

//	`log("displayArrow ::: icon=" @ObjArrow.icon @", loc=" @ObjArrow.Loc @", unitVState=" @unitVState);

    // ignore invalid arrows. It should never happen but...
    if (ObjArrow.icon == "")
    {
//	    `log("INVALID arrow");
        return;
    }
	
    // calculate new icon based on the unit state
    arrowIcon = class'GotchaUnitFlagHelper'.static.getNewArrowIcon(ObjArrow.icon, unitVState);
//    `log("new arrowIcon=" @arrowIcon);

    // display arrow if icon is new
    if (arrowIcon != "" && arrowIcon != ObjArrow.icon)
    {
        ArrowManager.AddArrowPointingAtLocation(ObjArrow.loc, ObjArrow.Offset, ObjArrow.arrowState, ObjArrow.arrowCounter, arrowIcon);
    }

}
