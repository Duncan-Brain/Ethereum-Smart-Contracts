pragma solidity ^0.4.24;

import "IsHex8RGBA.sol";

///@title An 500x500 array of pixels with the option to charge per pixel
///@dev TODO: Update to latest pragma

contract Canvas {
    bytes9[250000] public pixels;
    address public owner;
    address public manager;
    bool public isPaused = false;
    uint public pixelCost = 0 ether;
    uint256 public CANVAS_HEIGHT = 500;
    uint256 public CANVAS_WIDTH = 500;
    uint public counter = 0;

    mapping (address => uint) txMap;

    constructor(address owner_) public {
        owner = owner_;
        manager = msg.sender;
    }

    modifier isManager() {
        require(msg.sender == manager, "Only The Contract Manager Can Call This Function");
        _;
    }

    modifier isOwner(){
        require(msg.sender == owner, "Only The Contract Owner Can Call This Function");
        _;
    }

    function changeManager(address newManager) public isOwner {
        manager = newManager;
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function withdraw() public isOwner {
        owner.transfer(address(this).balance);
    }

    function pauseContract() public isManager {
        isPaused = !isPaused;
    }

    function getPixels() public view returns (bytes9[250000]) {
        return pixels;
    }

    function changePixelCost(uint newPixelCost) public isManager {
        pixelCost = newPixelCost;
    }

    function changePixel(string hex8RGBA, uint x, uint y) public payable {
        require(!isPaused, 'Contract Is Paused');
        require(msg.value >= pixelCost, 'Transaction Value Is Incorrect');
        require(IsHex8RGBA.matches(hex8RGBA), 'Invalid Hex #RRGGBBAA Color');
        require(x > 0 && x <= CANVAS_WIDTH, 'Invalid X Coordinate Value');
        require(y > 0 && y <= CANVAS_HEIGHT, 'Invalid Y Coordinate Value');
        require(txMap[msg.sender] != block.number, 'Only One Transaction Per Block');
        txMap[msg.sender] = block.number;
        uint index = (CANVAS_WIDTH * (y-1)) + (x-1);
        pixels[index] = stringToBytes9(hex8RGBA);
        counter++;
    }

    function clearPixels(uint xTopL, uint yTopL, uint xBottomR, uint yBottomR) public isManager {
        require(xTopL > 0 && xTopL <= CANVAS_WIDTH, 'Invalid X Coordinate Value');
        require(yTopL > 0 && yTopL <= CANVAS_HEIGHT, 'Invalid Y Coordinate Value');
        require(xBottomR > 0 && xBottomR <= CANVAS_WIDTH, 'Invalid X Coordinate Value');
        require(yBottomR > 0 && yBottomR <= CANVAS_HEIGHT, 'Invalid Y Coordinate Value');
        require(xTopL < xBottomR, 'Double Check Corner Coordinates');
        require(yTopL > yBottomR, 'Double Check Corner Coordinates');
        for(uint y = yTopL; y <= yBottomR; y++){
            for(uint x = xTopL; x <= xBottomR; x++){
                uint index = (CANVAS_WIDTH * (y-1)) + (x-1);
                pixels[index] = stringToBytes9('');
            }
        }
    }

    function stringToBytes9(string memory source) private pure returns (bytes9 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}
