# Lorenzo 奖励释放

1. Lorenzo后台定时统计SY合约的deposit事件. (可以复用现有的后端功能, 统计由SY合约地址发起的deposit)
2. 按5%的年化, 计算某一期应发的BANK奖励. 
3. 调用`PendleLorenzoSUsd1PlusReward`的`releaseReward`方法, 将奖励转存至PendleLorenzoSUsd1PlusReward合约中
4. Pendle系统再次claimReward时, 将BANK转入SY合约, 分配给用户. 