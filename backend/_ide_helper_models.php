<?php

// @formatter:off
// phpcs:ignoreFile
/**
 * A helper file for your Eloquent Models
 * Copy the phpDocs from this file to the correct Model,
 * And remove them from this file, to prevent double declarations.
 *
 * @author Barry vd. Heuvel <barryvdh@gmail.com>
 */


namespace App\Models{
/**
 * App\Models\Badge
 *
 * @property int $id
 * @property string $name
 * @property string $slug
 * @property int $tier
 * @property string|null $icon
 * @property string|null $description
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\User> $users
 * @property-read int|null $users_count
 * @method static \Illuminate\Database\Eloquent\Builder|Badge newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Badge newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Badge query()
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereDescription($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereIcon($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereSlug($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereTier($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Badge whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperBadge {}
}

namespace App\Models{
/**
 * App\Models\Category
 *
 * @property int $id
 * @property int $user_id
 * @property string $name
 * @property string $type
 * @property string $color
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Register> $registers
 * @property-read int|null $registers_count
 * @property-read \App\Models\User|null $users
 * @method static \Illuminate\Database\Eloquent\Builder|Category newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Category newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Category query()
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereColor($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Category whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperCategory {}
}

namespace App\Models{
/**
 * App\Models\Challenge
 *
 * @property int $id
 * @property string $name
 * @property string|null $description
 * @property bool $active
 * @property string|null $type
 * @property array|null $payload
 * @property float|null $target_amount
 * @property int $duration_days
 * @property int $reward_points
 * @property int|null $reward_badge_id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Badge|null $badge
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\User> $users
 * @property-read int|null $users_count
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge query()
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereActive($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereDescription($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereDurationDays($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge wherePayload($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereRewardBadgeId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereRewardPoints($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereTargetAmount($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Challenge whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperChallenge {}
}

namespace App\Models{
/**
 * App\Models\Currency
 *
 * @property int $id
 * @property string $code
 * @property string $name
 * @property string $symbol
 * @property string $rate
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\MoneyMaker> $moneyMakers
 * @property-read int|null $money_makers_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Register> $registers
 * @property-read int|null $registers_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\User> $users
 * @property-read int|null $users_count
 * @method static \Illuminate\Database\Eloquent\Builder|Currency code($code)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Currency newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Currency query()
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereCode($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereRate($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereSymbol($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Currency whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperCurrency {}
}

namespace App\Models{
/**
 * App\Models\DataApi
 *
 * @property int $id
 * @property string $name
 * @property string $type
 * @property string $balance
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi query()
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi whereBalance($value)
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder|DataApi whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperDataApi {}
}

namespace App\Models{
/**
 * App\Models\Goal
 *
 * @property int $id
 * @property int $user_id
 * @property int $category_id
 * @property string $name
 * @property string $target_amount
 * @property string $date_limit
 * @property string $balance
 * @property string $state
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Category|null $categories
 * @property-read \App\Models\User|null $users
 * @method static \Illuminate\Database\Eloquent\Builder|Goal newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Goal newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Goal query()
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereBalance($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereCategoryId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereDateLimit($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereState($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereTargetAmount($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Goal whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperGoal {}
}

namespace App\Models{
/**
 * App\Models\House
 *
 * @property int $id
 * @property int $user_id
 * @property int $unlocked_second_floor
 * @property int $unlocked_garage
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|House newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|House newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|House query()
 * @method static \Illuminate\Database\Eloquent\Builder|House whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|House whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|House whereUnlockedGarage($value)
 * @method static \Illuminate\Database\Eloquent\Builder|House whereUnlockedSecondFloor($value)
 * @method static \Illuminate\Database\Eloquent\Builder|House whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|House whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperHouse {}
}

namespace App\Models{
/**
 * App\Models\Mission
 *
 * @property int $id
 * @property string $period
 * @property string $name
 * @property string|null $description
 * @property string $type
 * @property array|null $payload
 * @property int $reward_points
 * @property int $active
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\UserMission> $userMissions
 * @property-read int|null $user_missions_count
 * @method static \Illuminate\Database\Eloquent\Builder|Mission newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Mission newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Mission query()
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereActive($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereDescription($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission wherePayload($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission wherePeriod($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereRewardPoints($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Mission whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperMission {}
}

namespace App\Models{
/**
 * App\Models\MoneyMaker
 *
 * @property int $id
 * @property int $user_id
 * @property string $name
 * @property string $type
 * @property string $balance
 * @property int $currency_id
 * @property string|null $color
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Currency $currency
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Register> $registers
 * @property-read int|null $registers_count
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker query()
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereBalance($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereColor($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereCurrencyId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|MoneyMaker whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperMoneyMaker {}
}

namespace App\Models{
/**
 * App\Models\ReactivationRequest
 *
 * @property int $id
 * @property int $user_id
 * @property string $requested_at
 * @property int $processed
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest query()
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest whereProcessed($value)
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest whereRequestedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|ReactivationRequest whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperReactivationRequest {}
}

namespace App\Models{
/**
 * App\Models\Register
 *
 * @property int $id
 * @property int $user_id
 * @property int $category_id
 * @property int $moneyMaker_id
 * @property string $name
 * @property string $balance
 * @property int $currency_id
 * @property string $type
 * @property string|null $file
 * @property int $repetition
 * @property string|null $frequency_repetition
 * @property int|null $goal_id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Category $category
 * @property-read \App\Models\Currency $currency
 * @property-read \App\Models\Goal|null $goal
 * @property-read \App\Models\MoneyMaker|null $moneyMaker
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|Register newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Register newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Register query()
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereBalance($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereCategoryId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereCurrencyId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereFile($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereFrequencyRepetition($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereGoalId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereMoneyMakerId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereRepetition($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereType($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Register whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperRegister {}
}

namespace App\Models{
/**
 * App\Models\User
 *
 * @property int $id
 * @property string $name
 * @property string $email
 * @property \Illuminate\Support\Carbon|null $email_verified_at
 * @property string $password
 * @property string|null $icon
 * @property int $currency_id
 * @property string $balance
 * @property \Illuminate\Support\Carbon|null $last_challenge_refresh
 * @property int $points
 * @property int $level
 * @property string|null $remember_token
 * @property int $active
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Badge> $badges
 * @property-read int|null $badges_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Category> $categories
 * @property-read int|null $categories_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Challenge> $challenges
 * @property-read int|null $challenges_count
 * @property-read \App\Models\Currency $currency
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Goal> $goals
 * @property-read int|null $goals_count
 * @property-read \App\Models\House|null $house
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\MoneyMaker> $moneyMakers
 * @property-read int|null $money_makers_count
 * @property-read \Illuminate\Notifications\DatabaseNotificationCollection<int, \Illuminate\Notifications\DatabaseNotification> $notifications
 * @property-read int|null $notifications_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Register> $registers
 * @property-read int|null $registers_count
 * @property-read \App\Models\UserStreak|null $streak
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \Laravel\Sanctum\PersonalAccessToken> $tokens
 * @property-read int|null $tokens_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\UserMission> $userMissions
 * @property-read int|null $user_missions_count
 * @method static \Illuminate\Database\Eloquent\Builder|User active()
 * @method static \Database\Factories\UserFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder|User newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|User newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|User query()
 * @method static \Illuminate\Database\Eloquent\Builder|User whereActive($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereBalance($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereCurrencyId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmail($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmailVerifiedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereIcon($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereLastChallengeRefresh($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereLevel($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User wherePassword($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User wherePoints($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereRememberToken($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereUpdatedAt($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperUser {}
}

namespace App\Models{
/**
 * App\Models\UserChallenge
 *
 * @property int $id
 * @property int $user_id
 * @property int $challenge_id
 * @property float $balance
 * @property string $state
 * @property array|null $payload
 * @property float|null $target_amount
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property float $progress
 * @property \Illuminate\Support\Carbon|null $start_date
 * @property \Illuminate\Support\Carbon|null $end_date
 * @property-read \App\Models\Challenge $challenge
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge query()
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereBalance($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereChallengeId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereEndDate($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge wherePayload($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereProgress($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereStartDate($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereState($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereTargetAmount($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserChallenge whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperUserChallenge {}
}

namespace App\Models{
/**
 * App\Models\UserMission
 *
 * @property int $id
 * @property int $mission_id
 * @property int $user_id
 * @property string $status
 * @property int $progress
 * @property int $target
 * @property string $start_at
 * @property string $end_at
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\Mission $mission
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission query()
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereEndAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereMissionId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereProgress($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereStartAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereStatus($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereTarget($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserMission whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperUserMission {}
}

namespace App\Models{
/**
 * App\Models\UserStreak
 *
 * @property int $id
 * @property int $user_id
 * @property int $current_streak
 * @property int $longest_streak
 * @property \Illuminate\Support\Carbon|null $last_activity_date
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \App\Models\User $user
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak query()
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereCurrentStreak($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereLastActivityDate($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereLongestStreak($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|UserStreak whereUserId($value)
 * @mixin \Eloquent
 */
	#[\AllowDynamicProperties]
	class IdeHelperUserStreak {}
}

