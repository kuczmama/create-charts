# Create Charts

- Take N days of Cryptocurrency data
- Plot N-1 days as a chart
- label day N as either up or down or neutral

```
percent_change = (coin[N] - coin[N-1]) / coin[N]
if(percent_change > TRESH_HOLD)
  label = 'up'
elif(percent_change < -TRESH_HOLD)
  label = 'down'
else
  label = 'flat'
end

```

- Save the chart as a png