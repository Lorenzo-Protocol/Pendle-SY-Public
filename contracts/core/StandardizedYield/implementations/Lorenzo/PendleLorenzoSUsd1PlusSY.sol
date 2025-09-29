// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "../../SYBaseWithRewardsUpg.sol";
import "../../../../interfaces/Lorenzo/ISUsd1PlusVault.sol";
import "../../../../interfaces/Lorenzo/ISUsd1PlusReward.sol";

contract PendleLorenzoSUsd1PlusSY is SYBaseWithRewardsUpg {
    using PMath for uint256;

    address public immutable sUSD1PlusVaultAddr;
    address public immutable rewardManagerAddr;
    address public immutable rewardTokenAddr;
    address public immutable usd1Addr;
    address public immutable usdtAddr;
    address public immutable usdcAddr;

    error InvalidTokenIn(address tokenIn);

    constructor(
        address _usd1,
        address _usdt,
        address _usdc,
        address _sUSD1Plus,
        address _rewardTokenMgrAddr
    )
        SYBaseUpg(_sUSD1Plus)
    {
        usd1Addr = _usd1;
        usdtAddr = _usdt;
        usdcAddr = _usdc;

        sUSD1PlusVaultAddr = _sUSD1Plus;
        rewardManagerAddr = _rewardTokenMgrAddr;
        rewardTokenAddr = address(ISUsd1PlusReward(rewardManagerAddr).rewardToken());

        require(rewardTokenAddr != _sUSD1Plus, "rewardTokenAddr is sUSD1Plus");
    }

    function initialize() external initializer {
        __SYBaseUpg_init("SY staked sUSD1+", "SY-sUSD1+");
    }

    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _deposit(address tokenIn, uint256 amountDeposited) internal virtual override returns (uint256) {
        if (tokenIn == sUSD1PlusVaultAddr) {
            return amountDeposited;
        }

        uint256 preBalance = _selfBalance(sUSD1PlusVaultAddr);

        IERC20(tokenIn).approve(sUSD1PlusVaultAddr, amountDeposited);
        ISUsd1PlusVault(sUSD1PlusVaultAddr).directDeposit(tokenIn, amountDeposited);

        return _selfBalance(sUSD1PlusVaultAddr) - preBalance;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256) {
        _transferOut(sUSD1PlusVaultAddr, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        return ISUsd1PlusVault(sUSD1PlusVaultAddr).getCurrentUnitNav();
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal view override returns (address[] memory) {
        return ArrayLib.create(rewardTokenAddr);
    }

    function _redeemExternalReward() internal override {
        ISUsd1PlusReward(rewardManagerAddr).claimRewards(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == sUSD1PlusVaultAddr) return amountTokenToDeposit;

        uint256 nav = ISUsd1PlusVault(sUSD1PlusVaultAddr).getCurrentUnitNav();
        return (amountTokenToDeposit * PMath.ONE) / nav;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(usd1Addr, usdtAddr, usdcAddr, sUSD1PlusVaultAddr);
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(sUSD1PlusVaultAddr);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == usd1Addr || token == usdtAddr || token == usdcAddr || token == sUSD1PlusVaultAddr;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == sUSD1PlusVaultAddr;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, usd1Addr, IERC20Metadata(usd1Addr).decimals());
    }
}
