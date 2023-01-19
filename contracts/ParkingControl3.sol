// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ParkingControl {
    address private _owner;
    mapping(address => bool) allowed_confirmers;
    mapping(address => bool) allowed_workers;
    mapping(address => string) req_address_plates;
    mapping(address => string) address_plates;
    mapping(address => string) address_visitorplates;
    mapping(string => Request) requests;
    mapping(string => Ticket) tickets;

    string[] public requests_plates;
    string[] public requests_places;

    constructor (){
        _owner = msg.sender;
        allowed_confirmers[_owner] = true;
        allowed_workers[_owner] = true;
    }

    struct Request {
        address req_address;
        string place;
        bool is_init;
    }

    struct Ticket {
        address ticket_owner;
        string place;
        uint256 exp_date;
        bool is_visitor;
        bool is_valid;
    }

    function claimParkingPass(string memory numbersplate, string memory place) public {
        require(!(requests[numbersplate].is_init), "Already requested ticket for this plate");
        require(bytes(req_address_plates[msg.sender]).length == 0, "Already requested ticket with this address");
        require(bytes(numbersplate).length != 0 || bytes(place).length != 0, "Can't claim parking pass without numbersplate or place");
        
        req_address_plates[msg.sender] = numbersplate;
        requests_plates.push(numbersplate);
        requests_places.push(place);

        requests[numbersplate] = Request(
            msg.sender,
            place,
            true
        );
    }

    function findPlateIndex(string memory value) private view returns(uint) {
        uint i = 0;
        while (keccak256(bytes(requests_plates[i])) != keccak256(bytes(value))) {
            i++;
        }
        return i;
    }

    function findPlaceIndex(string memory value) private view returns(uint) {
        uint i = 0;
        while (keccak256(bytes(requests_places[i])) != keccak256(bytes(value))) {
            i++;
        }
        return i;
    }

    function deleteRequest(string memory numbersplate) external {
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(requests[numbersplate].is_init, "No request for this plate");

        delete requests_plates[findPlateIndex(numbersplate)];
        delete requests_places[findPlaceIndex(requests[numbersplate].place)];
        delete requests[numbersplate];
    }

    function confirmParkingPass(string memory numbersplate) external {
        require(allowed_confirmers[msg.sender], "Insufficient permissions");
        require(requests[numbersplate].is_init, "No request for this plate");

        uint exp_date = block.timestamp + 365 days;

        // get request
        Request memory req = requests[numbersplate];
        // add address to mapping with plate
        address_plates[req.req_address] = numbersplate;

        tickets[numbersplate] = Ticket(
            req.req_address,
            req.place,
            exp_date,
            false,
            true
        );

        delete requests_places[findPlaceIndex(requests[numbersplate].place)];
        delete requests_plates[findPlaceIndex(numbersplate)];
        delete requests[numbersplate];
    } 

    function getRequests() external view returns(string[] memory, string[] memory){
        return (requests_plates, requests_places);
    }

    function verifyParkingPass(string memory numbersplate) external view returns (Ticket memory){
        require(allowed_workers[msg.sender], "Insufficient permissions");
        require(tickets[numbersplate].is_valid, "Plate not valid");
        require(tickets[numbersplate].exp_date > block.timestamp, "Ticket exceeded");

        return tickets[numbersplate];
    }

    function claimVisitorPass(string memory numbersplate_visitor) external {
        require(tickets[address_plates[msg.sender]].exp_date > block.timestamp, "Main parking ticket Ticket exceeded");

        // if wallet has created a visitor plate, check if its still valid
        if(bytes(address_visitorplates[msg.sender]).length != 0) {
            if(tickets[address_visitorplates[msg.sender]].exp_date > block.timestamp){
                // If visitor ticket is still valid, revert transaction
                revert("Address already has an active visitor ticket");
            } else {
                // If visitor ticket isn't valid anymore, delete it and proceed
                delete tickets[address_visitorplates[msg.sender]];
            }
        }

        string memory parent_plate = address_plates[msg.sender];
        // calculate expiring date of visitor ticket
        uint exp_date = block.timestamp + 60 days;

        // get main ticket
        Ticket memory parent_ticket = tickets[parent_plate];

        // check if calculated due date of visitor ticket is past due date of main ticket
        if (exp_date > parent_ticket.exp_date){
            // if so, set exp_date to the exp_date of the main ticket
            exp_date = parent_ticket.exp_date;
        }

        // insert new visitor plate
        address_visitorplates[msg.sender] = numbersplate_visitor;

        // insert new ticket for visitor
        tickets[numbersplate_visitor] = Ticket(
            msg.sender,
            parent_ticket.place,
            exp_date,
            true,
            true
        );
    }

     function renewParkingPass() external {
        require(tickets[address_plates[msg.sender]].is_valid, "No valid ticket for current wallet");

        claimParkingPass(address_plates[msg.sender], tickets[address_plates[msg.sender]].place);
    }

    function addConfirmer(address conf_address) external {
        require(msg.sender == _owner, "Insufficient permissions");
        allowed_confirmers[conf_address] = true;
    }

    function addWorker(address worker_address) external {
        require(msg.sender == _owner, "Insufficient permissions");
        allowed_workers[worker_address] = true;
    }

}
