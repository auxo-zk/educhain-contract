interface ClusterInfo {
  price: bigint;
  openForSell: bigint;
  sold: bigint;
  startSellTime: bigint;
  isNotForSell: boolean;
}

export const createClusterInfos = (
  prices: Array<bigint>,
  openForSells: Array<bigint>,
  startSellTimes: Array<bigint>
): Array<ClusterInfo> => {
  let clustorInfos: Array<ClusterInfo> = [];

  for (let i = 0; i < prices.length; i++) {
    clustorInfos.push({
      price: prices[i],
      openForSell: openForSells[i],
      sold: 0n,
      startSellTime: startSellTimes[i],
      isNotForSell: false,
    });
  }
  return clustorInfos;
};
