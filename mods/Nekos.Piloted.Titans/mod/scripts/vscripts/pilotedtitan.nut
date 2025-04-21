global function pilotedtitan_init

struct
{
array<entity> props
table<entity, entity> propsowner
table<entity, entity> playersprop
}file

void function pilotedtitan_init()
{
Pilotedtitan()
AddCallback_OnPilotBecomesTitan( OnPilotBecomesTitan )
AddCallback_OnTitanBecomesPilot( OnTitanBecomesPilot )
}

void function OnTitanBecomesPilot( entity pilot, entity titan )
{
entity playersprop = file.playersprop[pilot]
if( IsValid( playersprop ) )
playersprop.Destroy()
}

void function OnPilotBecomesTitan( entity pilot, entity titan )
{
 if( !pilot.IsTitan() )
 {
 entity prop = CreatePropDynamic( pilot.GetModelName() )
 file.playersprop[pilot] = prop
 file.propsowner[prop] = pilot
 file.props.append( prop )
 }
 if( pilot.IsTitan() )
 {
 entity model = Wallrun_CreateCopyOfPilotModel( pilot )
 entity prop = CreatePropDynamic( model.GetModelName() )
 /*
 entity prop = CreateEntity( "npc_pilot_elite" )
 prop.SetModel( model.GetModelName() )
 SetTeam( prop, pilot.GetTeam() )
 prop.SetInvulnerable()
 DispatchSpawn( prop )
 SetTeam( prop, pilot.GetTeam() )
 prop.SetModel( model.GetModelName() )
 TakeWeaponsForArray( prop, prop.GetMainWeapons() )
 */
 file.playersprop[pilot] <- prop
 file.propsowner[prop] <- pilot
 file.props.append( prop )
 model.Destroy()
 }
}

void function Pilotedtitan()
{
thread Pilotedtitan_thread()
}

void function Pilotedtitan_thread()
{
 while( true )
 {
  foreach( entity prop in file.props )
  {
   if( IsValid( prop ) )
   {
   entity propsowner = file.propsowner[prop]
   if( !IsValid( propsowner ) )
   prop.Destroy()
   if( prop.GetTeam() != propsowner.GetTeam() )
   SetTeam( prop, propsowner.GetTeam() )
   FirstPersonSequenceStruct sequence
   sequence.attachment = "hijack"
   sequence.useAnimatedRefAttachment = true
   sequence.blendTime = 0
   sequence.thirdPersonAnim = "pt_ht_synced_bt_execute_kickshoot_V"
   thread FirstPersonSequence( sequence, prop, propsowner )
   prop.kv.VisibilityFlags = propsowner.kv.VisibilityFlags
   }
  }
  WaitFrame()
 }
}