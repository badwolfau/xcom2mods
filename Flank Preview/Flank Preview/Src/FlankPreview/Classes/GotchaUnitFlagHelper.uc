class GotchaUnitFlagHelper extends Object;

enum EUnitVisibilityState
{
    eUVS_NotVisible,
    eUVS_Spotted,
    eUVS_Flanked,
    eUVS_SquadSight,
    eUVS_SquadSightFlanked,
    eUVS_Hacking
};

struct UnitArrowIconSet
{
	var string		defaultIcon;
	var string		spottedIcon;
	var string		flankedIcon;
	var string		squadsightIcon;
	var string		squadsightFlankedIcon;
	var string		hackingIcon;
};

//var array<UnitArrowIconSet> arrowIconSetArr;
var UnitArrowIconSet
        IconSet_Objective_DestroyAlienFacility,
        IconSet_Objective_HackWorkstation,
        IconSet_Objective_RecoverItem,
        IconSet_Objective_Broadcast;

defaultproperties
{
    // TODO: use array of icons instead of separate variables
    //    arrowIconSetArr = (
    //        (defaultIcon="img:///UILibrary_Common.Objective_DestroyAlienFacility", spottedIcon="img:///Gotcha.TargetIcons.Objective_DestroyAlienFacility_spotted")
    //        UnitArrowIconSet("img:///UILibrary_Common.Objective_DestroyAlienFacility", "img:///Gotcha.TargetIcons.Objective_DestroyAlienFacility_spotted")
    //    );

    // Destroy alien transmitter
    IconSet_Objective_DestroyAlienFacility = {(
        defaultIcon = "img:///UILibrary_Common.Objective_DestroyAlienFacility",
        spottedIcon = "img:///Gotcha.TargetIcons.Objective_DestroyAlienFacility_spotted",
        squadsightIcon = "img:///Gotcha.TargetIcons.Objective_DestroyAlienFacility_squadsight",
    )};

    // Workstation hack
    IconSet_Objective_HackWorkstation = {(
        defaultIcon = "img:///UILibrary_Common.Objective_HackWorkstation",
        hackingIcon = "img:///Gotcha.TargetIcons.Objective_HackWorkstation_hack",
    )};

    // Mission: Recover Item from train
    IconSet_Objective_RecoverItem = {(
        defaultIcon = "img:///UILibrary_Common.Objective_RecoverItem",
        hackingIcon = "img:///Gotcha.TargetIcons.Objective_RecoverItem_hack",
    )};

    // Broadcast hack (second last mission)
    // TODO: set new icon
    IconSet_Objective_Broadcast = {(
        defaultIcon = "img:///UILibrary_Common.Objective_Broadcast",
        hackingIcon = "img:///UILibrary_Common.Objective_Broadcast",
    )};

    // UFO hack
    //			"img:///UILibrary_Common.Objective_UFO":

}

//
static function string getNewArrowIcon(string currentIcon, EUnitVisibilityState unitVState)
{
    local UnitArrowIconSet arrowIconSet;

//    `log("getNewArrowIcon :: currentIcon = " @ currentIcon @", unitVState=" @unitVState);

    arrowIconSet = getUnitArrowIconSet(currentIcon);
    if (arrowIconSet.defaultIcon == "") // if icon set not found
    {
        return currentIcon;
    }

    switch(unitVState)
    {
        case eUVS_Spotted:              return arrowIconSet.spottedIcon;
        case eUVS_Flanked:              return arrowIconSet.flankedIcon;
        case eUVS_SquadSight:           return arrowIconSet.squadsightIcon;
        case eUVS_SquadSightFlanked:    return arrowIconSet.squadsightFlankedIcon;
        case eUVS_Hacking:              return arrowIconSet.hackingIcon;
        default:
            return arrowIconSet.defaultIcon;
    }
}

static function UnitArrowIconSet getUnitArrowIconSet(string currentIcon)
{
    local UnitArrowIconSet arrowIconSet, arrowIconSetNone;
    local array<UnitArrowIconSet> arrowIconSetArr;

    arrowIconSetArr.addItem(default.IconSet_Objective_DestroyAlienFacility); // TODO: make it static
    arrowIconSetArr.addItem(default.IconSet_Objective_HackWorkstation); // TODO: make it static
    arrowIconSetArr.addItem(default.IconSet_Objective_RecoverItem); // TODO: make it static
    arrowIconSetArr.addItem(default.IconSet_Objective_Broadcast); // TODO: make it static

    foreach arrowIconSetArr(arrowIconSet)
    {
//        `log("arrowIconSet.defaultIcon = " @ arrowIconSet.defaultIcon);
        if (currentIcon == arrowIconSet.defaultIcon
            || currentIcon == arrowIconSet.spottedIcon
            || currentIcon == arrowIconSet.flankedIcon
            || currentIcon == arrowIconSet.squadsightIcon
            || currentIcon == arrowIconSet.squadsightFlankedIcon
            || currentIcon == arrowIconSet.hackingIcon )
        {
            return arrowIconSet;
        }
    }
    return arrowIconSetNone;
}

// extract unit location from UnitFlag
static function vector getUnitFlagLocation(UIUnitFlag kFlag)
{
    local vector vUnitLoc;
    local X2VisualizerInterface VisualizedInterface;
    local Actor VisualizedActor;

    // Now get the unit's location data
    VisualizedActor = `XCOMHISTORY.GetVisualizer(kFlag.StoredObjectID);
    VisualizedInterface = X2VisualizerInterface(VisualizedActor);
    if (VisualizedInterface != none)
    {
        vUnitLoc = VisualizedInterface.GetUnitFlagLocation();
    }
    else
    {
        vUnitLoc = VisualizedActor.Location;
    }

    return vUnitLoc;
}