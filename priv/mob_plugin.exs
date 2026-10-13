%{
  name: :mob_mishka,
  mob_version: "~> 0.9",
  plugin_spec_version: 1,
  description: "Mishka Chelekom composites for Mob apps — plugin-shipped",
  # On-device proof for `mix mob.selftest` / mob_ci: every composite registered
  # with Mob.Composite at boot, and a MishkaSwitch + MishkaProgress tree
  # expanded into the native widget shape (Mob.Plugin.SelfTest).
  selftest: MobMishka.SelfTest,

  # PascalCase tags this plugin contributes to the `~MOB` sigil whitelist.
  # See MOB-247 in mob for how the sigil reads this list at compile time.
  #
  # Two groups, each mirrored by a function in `MobMishka`:
  #
  #   1. Composite tags — every one matches a `{tag_atom, module}` entry in
  #      `MobMishka.composites/0`, registered at boot by `register_all/0`.
  #   2. Slot tags — `MobMishka.slot_tags/0`. Children a parent composite's
  #      `expand/3` consumes by `:type` (the native analogue of a Chelekom
  #      `<:slot>`, e.g. `<MishkaPopoverTrigger>` inside `<MishkaPopover>`).
  #      They have no expander, but the sigil still validates them as tags.
  #
  # Also accepts a per-platform map:
  #
  #     tags: %{ios: ~w(FooIOS), android: ~w(FooAndroid), both: ~w(FooShared)}
  tags: ~w(
    MishkaAccordion
    MishkaActionIcon
    MishkaAlertDialog
    MishkaAlphaSlider
    MishkaAnchor
    MishkaAngleSlider
    MishkaAutocomplete
    MishkaAvatar
    MishkaBurger
    MishkaCheckbox
    MishkaCheckboxGroup
    MishkaChip
    MishkaCloseButton
    MishkaCode
    MishkaCollapsible
    MishkaColorInput
    MishkaColorPicker
    MishkaColorSwatch
    MishkaCombobox
    MishkaContextMenu
    MishkaDialog
    MishkaDrawer
    MishkaEmptyState
    MishkaField
    MishkaFieldset
    MishkaFloatingIndicator
    MishkaFloatingWindow
    MishkaHighlight
    MishkaHueSlider
    MishkaJsonInput
    MishkaLoadingOverlay
    MishkaMark
    MishkaMarquee
    MishkaMaskInput
    MishkaMenu
    MishkaMenubar
    MishkaMeter
    MishkaNavLink
    MishkaNavigationMenu
    MishkaNumberField
    MishkaNumberFormatter
    MishkaOtpField
    MishkaOverflowList
    MishkaPill
    MishkaPillsInput
    MishkaPopover
    MishkaPreviewCard
    MishkaProgress
    MishkaRadio
    MishkaRadioGroup
    MishkaRollingNumber
    MishkaScrollArea
    MishkaScroller
    MishkaSegmentedControl
    MishkaSelect
    MishkaSemiCircleProgress
    MishkaSeparator
    MishkaSkeleton
    MishkaSlider
    MishkaSplitter
    MishkaSpoiler
    MishkaSwitch
    MishkaTabs
    MishkaTagsInput
    MishkaThemeIcon
    MishkaToast
    MishkaToggle
    MishkaToggleGroup
    MishkaToolbar
    MishkaTooltip
    MishkaTree
    MishkaTreeSelect
    MishkaVisuallyHidden
  ) ++
    ~w(
      MishkaAccordionItem
      MishkaAlertDialogAction
      MishkaCheckboxGroupItem
      MishkaDialogDescription
      MishkaDialogFooter
      MishkaDialogTitle
      MishkaDialogTrigger
      MishkaDrawerFooter
      MishkaDrawerTrigger
      MishkaEmptyStateActions
      MishkaEmptyStateIndicator
      MishkaFloatingWindowHandle
      MishkaMenuCheckbox
      MishkaMenuItem
      MishkaMenuLabel
      MishkaMenuRadio
      MishkaMenuSeparator
      MishkaMenuSubmenu
      MishkaPopoverArrow
      MishkaPopoverClose
      MishkaPopoverDescription
      MishkaPopoverTitle
      MishkaPopoverTrigger
      MishkaPreviewCardTrigger
      MishkaRadioGroupOption
      MishkaSegmentedControlOption
      MishkaSelectOption
      MishkaTab
      MishkaToastClose
      MishkaToastItem
      MishkaToggleGroupItem
      MishkaToolbarButton
      MishkaToolbarInput
      MishkaToolbarLink
      MishkaToolbarSeparator
      MishkaTreeNode
    ),

  # Runs at host app boot (called by `Mob.Plugins.Lifecycle` after the
  # plugin's application has started). Registers every composite listed in
  # `MobMishka.composites/0` into the host's `Mob.Composite` table so
  # `<MishkaTabs />` in `~MOB` resolves to `{MobMishka.Components.MishkaTabs,
  # :expand}` at render time.
  lifecycle: %{
    on_start: {MobMishka, :register_all, []}
  }
}
