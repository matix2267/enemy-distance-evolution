# Enemy Distance Evolution

## What this mod does

It changes enemy spawners to evolve based on distance from map center instead of evolution factor.

> [!CAUTION]
> It's not possible to disable spawner HP scaling implemented in base game. Because of that it's
> highly recommended to turn off base game evolution altogether. Alternatively you can disable the
> HP scaling introduced by this mod in settings.

> [!TIP]
> If you're playing with enemy expansions turned on you may want to also reduce the maximum cooldown
> between expansions to account for the evolution factor being always zero.

## Why?

This allows for much less stressful base-building (removes time pressure) while still stopping the
player from expanding too quickly.

[_"Everything you build can be unbuilt, any mistake erased without judgement."_][1]

This was requested quite a few times on the forums in the past:

- [Tiered difficulty for nests][2]
- [Geo evolution][3]
- [Enemy level based on distance][4]

Possibly the best rationale comes from this comment: [Re: [REQUEST] Per-spawner evolution][5].

I couldn't find a mod implementing exactly what I wanted so I built my own.

### Why don't you just change the settings already available in the game?

Turning off evolution completely means that only small biters are ever produced. This means there's
absolutely no pressure from biter attacks. The only threat are worms which do evolve with distance
even in the base game.

Only enabling evolution by destroying nests does remove time pressure but the evolution mechanism is
still quite counterintuitive. You get punished for clearing out enemies. Optimal play is to only
clear out near the outposts to keep evolution factor low.

[1]: https://www.factorio.com/blog/post/fff-383#:~:text=everything%20you%20build%20can%20be%20unbuilt%2C%20any%20mistake%20erased%20without%20judgement
[2]: https://forums.factorio.com/viewtopic.php?p=459825#p459825
[3]: https://forums.factorio.com/viewtopic.php?p=542142#p542142
[4]: https://forums.factorio.com/viewtopic.php?p=620182#p620182
[5]: https://forums.factorio.com/viewtopic.php?p=599512#p599512

## Implementation Details

The mod works by creating multiple copies of each enemy spawner prototype, one per level. The number
of levels is configurable (default 10). These level-based prototypes have all properties identical
to the original except for the following:

- HP is scaled exponentially (same curve as base game) based on the level, up to 10x (configurable)
- Enemy type probability table does not depend on evolution factor at all, instead it's set to a
  value appropriate for the level of the spawner
- Enemy spawning cooldown is scaled based on the level instead of evolution factor

When generating new chunks all spawners are replaced with a leveled spawner based on its position on
the map. The distance parameters can be customised in mod settings.

> [!TIP]
> You can see the level of a particular spawner by looking at its name.

> [!NOTE]
> If you're playing with enemy expansions turned on the newly created nests will inherit the level
> from the nests that sent the expansion party. This seems to be non-overridable by mods.

## Compatibility

### Can I add this mod to an existing save?

Yes. When you first load this mod all non-leveled spawners will be converted to leveled ones based
on their positions.

### Can I remove this mod from a save?

If you remove this mod any spawners in already created chunks will be removed. Let me know if this
feature would be useful to you.

### Is this mod compatible with Factorio: Space Age?

Probably. I haven't yet played Space Age but the implementation is generic enough that it should
work without any changes.

### Is this mod compatible with [insert mod name]?

Maybe. If the mod in question adds new enemy types that utilise base game's evolution factor and
hooks into game's chunk generation code then it should work out-of-the-box.

If the mod dynamically creates entities then it needs to add `raise_built = true` to the
`create_entity` call.

Mods that do more significant overhauls of evolution mechanics or have complex dynamic spawning
logic may have unintended side-effects.

Let me know if you encounter any incompatibility.
