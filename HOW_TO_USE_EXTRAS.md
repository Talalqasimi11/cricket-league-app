# How to Use the Enhanced Extras Tracking System

## For Developers

### Recording Extras via API

#### 1. Wide (adds 1 run + any additional runs)
```javascript
POST /api/live/ball
{
  "match_id": "123",
  "inning_id": "456",
  "over_number": 3,      // Current over (0-based)
  "ball_number": 2,      // Current ball (1-6)
  "batsman_id": 10,
  "bowler_id": 20,
  "runs": 1,             // Wide penalty (1) + any runs scored
  "extras": "wide"       // Marks as wide
}
```
**Result**: Same over.ball is reused with sequence=1, ball_number stays 2

#### 2. No-Ball (adds 1 run + runs off bat)
```javascript
POST /api/live/ball
{
  "match_id": "123",
  "inning_id": "456",
  "over_number": 3,
  "ball_number": 2,
  "batsman_id": 10,
  "bowler_id": 20,
  "runs": 5,             // No-ball penalty (1) + runs off bat (4) = 5
  "extras": "no-ball"
}
```
**Result**: Sequence increments, ball_number stays same

#### 3. Bye/Leg-Bye (unearned runs, counts as legal ball)
```javascript
POST /api/live/ball
{
  "match_id": "123",
  "inning_id": "456",
  "over_number": 3,
  "ball_number": 2,
  "batsman_id": 10,
  "bowler_id": 20,
  "runs": 2,             // Runs scored via bye/leg-bye
  "extras": "bye"        // or "leg-bye"
}
```
**Result**: Ball advances normally (legal ball), sequence=0

### Understanding Sequence Numbers

```
Example: Over 3, Ball 2 with multiple events

Database entries:
| inning_id | over_number | ball_number | sequence | extras    | runs |
|-----------|-------------|-------------|----------|-----------|------|
| 1         | 3           | 2           | 0        | wide      | 1    |
| 1         | 3           | 2           | 1        | no-ball   | 1    |
| 1         | 3           | 2           | 2        | NULL      | 4    | <- Legal ball finally delivered

Frontend display: "3.2wd", "3.2nb", "3.2" (all shown separately)
```

### Query Examples

#### Get all balls for an innings (ordered correctly)
```sql
SELECT * FROM ball_by_ball
WHERE inning_id = 456
ORDER BY over_number ASC, ball_number ASC, sequence ASC;
```

#### Count legal balls only (for over calculation)
```sql
SELECT COUNT(*) as legal_balls
FROM ball_by_ball
WHERE inning_id = 456
  AND (extras IS NULL OR extras NOT IN ('wide', 'no-ball'));
```

#### Get extras summary
```sql
SELECT 
  extras,
  COUNT(*) as count,
  SUM(runs) as total_runs
FROM ball_by_ball
WHERE inning_id = 456
  AND extras IS NOT NULL
GROUP BY extras;
```

## For Frontend Developers

### Displaying Ball Information

The `BallByBall` model now includes helper methods:

```dart
import 'package:your_app/models/ball_by_ball.dart';

BallByBall ball = BallByBall.fromJson(jsonData);

// Get formatted display string
print(ball.ballDisplay);
// Output: "3.2wd" for wide, "3.2" for legal ball

// Check if ball is legal (counts toward over)
if (ball.isLegalDelivery) {
  // This ball advances the over count
}

// Access extras type
if (ball.extras == 'wide') {
  // Show wide indicator
}
```

### UI Component Examples

#### Ball Card with Extras Indicator
```dart
Widget buildBallCard(BallByBall ball) {
  final hasExtras = ball.extras != null;
  
  return Container(
    decoration: BoxDecoration(
      border: hasExtras 
        ? Border.all(color: Colors.orange, width: 1.5)
        : null,
    ),
    child: Row(
      children: [
        // Over display
        Text(ball.ballDisplay), // "3.2wd"
        
        // Extras badge
        if (ball.extras == 'wide')
          Chip(label: Text('WD')),
        if (ball.extras == 'no-ball')
          Chip(label: Text('NB')),
          
        // Runs
        Text('${ball.runs}'),
      ],
    ),
  );
}
```

#### Commentary Generation
```dart
String getCommentary(BallByBall ball) {
  if (ball.wicketType != null) {
    return 'Wicket: ${ball.wicketType}';
  }
  
  switch (ball.extras) {
    case 'wide':
      return 'Wide + ${ball.runs} runs';
    case 'no-ball':
      return 'No ball + ${ball.runs} runs';
    case 'bye':
      return 'Byes: ${ball.runs}';
    case 'leg-bye':
      return 'Leg byes: ${ball.runs}';
    default:
      return 'Runs: ${ball.runs}';
  }
}
```

## For Scorers (Using the App)

### Recording a Wide
1. Tap "Extras" button
2. Select "Wide"
3. Enter additional runs (default: 1)
4. Tap "Add Extra"

**Result**: Score increases by runs entered, over stays same (e.g., still 3.2)

### Recording a No-Ball
1. Tap "Extras" button
2. Select "No Ball"
3. Enter runs (no-ball penalty + runs scored, e.g., 5 for a no-ball four)
4. Tap "Add Extra"

**Result**: Score increases, over stays same, next ball is still on same number

### Recording a Bye/Leg-Bye
1. Tap "Extras" button
2. Select "Bye" or "Leg Bye"
3. Enter runs scored
4. Tap "Add Extra"

**Result**: Score increases, over progresses normally (counts as legal ball)

### Understanding Over Display

- **Normal ball**: `3.2` → Over 3, Ball 2
- **Wide**: `3.2wd` → Wide on Over 3, Ball 2
- **No-ball**: `3.2nb` → No-ball on Over 3, Ball 2
- **Bye**: `3.2b` → Bye on Over 3, Ball 2
- **Leg-bye**: `3.2lb` → Leg-bye on Over 3, Ball 2

## Common Scenarios

### Scenario 1: Multiple Wides in a Row
```
Ball 1: 3.1 (legal ball, 1 run)
Ball 2: 3.2wd (wide, 1 run) → stays 3.2
Ball 3: 3.2wd (another wide, 1 run) → sequence=1, still 3.2
Ball 4: 3.2 (legal ball finally, 2 runs) → sequence=2, now advances to 3.3
```

### Scenario 2: No-Ball + Runs
```
Ball 1: 3.2nb (no-ball, 5 runs = 1 penalty + 4 runs) → stays 3.2
Ball 2: 3.2 (legal ball, 0 runs) → sequence=1, advances to 3.3
```

### Scenario 3: Bye vs Wide
```
Bye:     3.2b (2 runs) → Advances to 3.3 (legal ball)
Wide:    3.2wd (1 run) → Stays at 3.2 (illegal ball)
```

## Rules Summary

### Legal Balls (Advance Over):
- Normal deliveries (no extras)
- Byes
- Leg-byes

### Illegal Balls (Don't Advance Over):
- Wides
- No-balls

### Over Progression:
- 6 legal balls = 1 over complete
- Wides/No-balls are "extra" deliveries
- Example: If over has 2 wides, you need 8 total deliveries for the over to complete

### Runs Tracking:
- All runs (legal or illegal) add to team total
- Bowler's economy rate uses legal balls only
- Batsman's strike rate uses balls faced (legal balls where they were on strike)

## Troubleshooting

### Issue: "Duplicate entry" error
**Cause**: Trying to insert same over/ball/sequence combination twice
**Solution**: Backend automatically calculates sequence - ensure you're not manually setting it

### Issue: Over not advancing after 6 balls
**Cause**: Some balls were wides/no-balls (illegal)
**Solution**: This is correct! Over only advances after 6 legal balls

### Issue: Balls showing in wrong order
**Cause**: Not sorting by sequence
**Solution**: Always ORDER BY over_number, ball_number, sequence

### Issue: Overs display showing decimals incorrectly
**Cause**: Including wides/no-balls in ball count
**Solution**: Use `legal_balls` count: `overs = legal_balls / 6`, `balls_in_over = legal_balls % 6`

## Support

For issues or questions:
1. Check `SEQUENCE_FIX_SUMMARY.md` for implementation details
2. Review API contract in summary document
3. Test with sample data using Postman
4. Check backend logs for sequence calculation

---
Last Updated: 2025-11-09
