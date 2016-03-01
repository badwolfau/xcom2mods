class FlankPreviewFlagManager extends UIUnitFlagManager;

var array<UIUnitFlag> flankedUnitsArr;

function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int Index;
	local UIUnitFlag kFlag;
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local XComGameState_Unit SourceUnitState, TargetUnitState;
	local XComGameState_BaseObject flagObj;
	local XComGameState_Destructible destructibleObject;
	local XComGameState_InteractiveObject interactiveObject;

    // reset flankedArr to prevent a memory leak
	if (m_arrFlags.length == 0) {
	    flankedUnitsArr.length = 0;
	}

//    `log("------------------");
//    `log("UNIT = " @ m_lastActiveUnit);

    SourceUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_lastActiveUnit.ObjectID,,-1));

	foreach m_arrFlags(kFlag)
	{
	    if (kFlag.m_bIsFriendly) continue;

	    flagObj = `XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID,,-1);
//	    `log("kFlag = " @ flagObj);

	    TargetUnitState = XComGameState_Unit(flagObj);
	    destructibleObject = XComGameState_Destructible(flagObj);
	    interactiveObject = XComGameState_InteractiveObject(flagObj);


        // Interactive Objects (e.g. door)
        if (interactiveObject != none) {
            // can see via SquadSight
            if (`XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, interactiveObject.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
            {
                if (SourceUnitState.HasSquadSight())
                {
                    // display red icon
                    SetSpottedAndFlankedState(kFlag, true, false);
                }
                else
                {
                    SetSpottedAndFlankedState(kFlag, VisibilityInfo.DefaultTargetDist <= (SourceUnitState.GetVisibilityRadius() * 100000), false); //What are these units??
                }
            }
            else
            {
                // remove 'spotted' icon
                SetSpottedAndFlankedState(kFlag, false, false);
            }
            continue;
        }

        // Enemy Units
	    if (TargetUnitState != none) {
	        Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
	        if (Index == INDEX_NONE)
            {
                // can see via SquadSight
                if (SourceUnitState.HasSquadSight() && `XWORLD.CanSeeTileToTile(MoveToTileData.EventTile, TargetUnitState.TileLocation, VisibilityInfo) && VisibilityInfo.bClearLOS)
                {
                    displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo);
                }
                else
                {
                    // remove 'spotted' icon
                    SetSpottedAndFlankedState(kFlag, false, false);
                }
            }
            else
            {
                VisibilityInfo = MoveToTileData.VisibleEnemies[Index];
                displaySpottedIcon(kFlag, MoveToTileData.EventTile, SourceUnitState, TargetUnitState, VisibilityInfo);
            }
            continue;
	    }

        // Destructible Objects (e.g. barrels)
	    if (destructibleObject != none) {
	        continue;
        }

	}
}

private function displaySpottedIcon(UIUnitFlag kFlag,
                           TTile tile,
                           XComGameState_Unit SourceUnitState,
                           XComGameState_Unit TargetUnitState,
                           GameRulesCache_VisibilityInfo VisibilityInfo)
{
    // if flanked
    if (class'FlankPreviewVisibilityHelper'.static.IsFlankedByLocation(tile, SourceUnitState, TargetUnitState, VisibilityInfo))
    {
        // display yellow icon
        SetSpottedAndFlankedState(kFlag, true, true);
    }
    else
    {
        // display red icon
        SetSpottedAndFlankedState(kFlag, true, false);
    }
}

function SetSpottedAndFlankedState(UIUnitFlag kFlag, bool spotted, bool flanked)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local bool m_bFlanked;

	m_bFlanked = (flankedUnitsArr.find(kFlag) != INDEX_NONE);

	if (spotted == kFlag.m_bSpotted && flanked == m_bFlanked) return;

    // save the state
	kFlag.m_bSpotted = spotted;

	if (flanked) {
	    flankedUnitsArr.addItem(kFlag);
	} else {
	    flankedUnitsArr.removeItem(kFlag);
	}

    // display
	myValue.Type = AS_Boolean;
	myValue.b = spotted;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
    myValue.b = flanked;
    myArray.AddItem( myValue );

	kFlag.Invoke("SetSpottedState", myArray);
}
