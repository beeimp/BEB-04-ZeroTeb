// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IZeroTEB.sol";
import "@klaytn/contracts/access/Ownable.sol";
import "@klaytn/contracts/utils/Counters.sol";
import "@klaytn/contracts/KIP/token/KIP17/KIP17.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17URIStorage.sol";

contract ZeroTEB is IZeroTEB, Ownable, KIP17URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _eventIds;
    Counters.Counter private _tokenIds;

    // 이벤트 구조체
    struct EventClass {
        string name;
        uint256 price;
        uint256 count;
        uint256[] tokens;
        address[] owners;
        uint256 index;
        uint256 ownerTotal;
    }

    struct Event {
        string name;
        uint8 eventType; // 0 - sale, 1 - entry
        string tokenImageUri;
        address creator;
        uint256 classCount;
        uint256 openTime;
        uint256 startTime;
        uint256 closeTime;
        uint256 endTime;
        uint8 status; // 0 - init, 1 - minted, 2 - sale or winners, 2 - end
        mapping(uint8 => EventClass) class;
    }

    // 토큰 확장 구조체
    struct TokenExtention {
        uint256 eventId;
        bool isTrade;
        uint8 tokenType;
    }

    /*
     * Mapping
     */
    mapping(uint256 => Event) private _events;
    mapping(uint256 => TokenExtention) private _tokenExtentions;
    mapping(uint256 => address[]) private _eventParticipants; // 이벤트 응모 참가자
    mapping(uint256 => bool) private _isEventWinners;
    mapping(uint256 => uint256) private _deposits;
    mapping(uint256 => uint256) private _amounts;

    /*
     * Modifier
     */
    modifier isEndEvent(uint256 _eventId) {
        require(
            block.timestamp > _events[_eventId].endTime,
            "This Event is not close."
        );
        _;
    }
    modifier isNFT(uint256 _tokenId) {
        require(
            _tokenExtentions[_tokenId].tokenType == 0,
            "This Token is not NFT."
        );
        _;
    }

    modifier isSale(uint256 _eventId) {
        require(_events[_eventId].eventType == 0, "This event is not sale.");
        _;
    }

    modifier isEntry(uint256 _eventId) {
        require(_events[_eventId].eventType == 1, "This event is not entry.");
        _;
    }

    constructor(string memory _name, string memory _symbol)
        KIP17(_name, _symbol)
    {}

    function eventOf(uint _tokenId) public view returns (uint) {
        return _tokenExtentions[_tokenId].eventId;
    }

    function totalEvent() public view returns (uint256) {
        return _eventIds.current();
    }

    function eventType(uint256 _eventId) public view returns (uint8) {
        return _events[_eventId].eventType;
    }

    function getEventClassCount(uint256 _eventId)
        public
        view
        returns (uint256)
    {
        return _events[_eventId].classCount;
    }

    function createEvent(
        address _creator,
        string memory _eventName,
        uint8 _eventType,
        string memory _tokenImageUri,
        string[] memory _classNames,
        uint256[] memory _classPrices,
        uint256[] memory _classCounts,
        uint256 _openTime,
        uint256 _closeTime,
        uint256 _startTime,
        uint256 _endTime
    ) public payable override returns (uint256 _eventId) {
        _eventIds.increment();

        uint256 _total = 0;
        uint256 _deposit = 0;
        for (uint256 i = 0; i < _classPrices.length; i++) {
            _total = _total + (_classPrices[i] * _classCounts[i]);
        }
        _total = _total * 1 ether;
        _deposit = (_total / 100) * 5;
        require(_deposit == msg.value, "The deposit does not fit.");
        address _owner = owner();
        payable(_owner).transfer((_deposit / 10) * 4);
        _deposits[_eventId] = (_deposit / 10) * 6;
        // 이벤트 아이디
        uint256 _newEventId = _eventIds.current();

        // 신규 이벤트 매핑
        _events[_newEventId].name = _eventName;
        _events[_newEventId].eventType = _eventType;
        _events[_newEventId].tokenImageUri = _tokenImageUri;
        _events[_newEventId].creator = _creator;
        _events[_newEventId].openTime = _openTime;
        _events[_newEventId].closeTime = _closeTime;
        _events[_newEventId].startTime = _startTime;
        _events[_newEventId].endTime = _endTime;
        _events[_newEventId].classCount = _classNames.length;
        _events[_newEventId].status = 0; // init status

        for (uint8 i = 0; i < _classNames.length; i++) {
            _events[_newEventId].class[i].name = _classNames[i];
            _events[_newEventId].class[i].count = _classPrices[i];
            _events[_newEventId].class[i].price = _classCounts[i];
            _events[_newEventId].class[i].tokens = new uint256[](
                _classCounts[i]
            );
            _events[_newEventId].class[i].owners = new address[](
                _classCounts[i]
            );
            _events[_newEventId].class[i].index = 0;
            _events[_newEventId].class[i].ownerTotal = 0;
        }
        _amounts[_newEventId] = 0;
        // 반환
        _eventId = _newEventId;
    }

    // 이벤트 조회
    function getEvent(uint _eventId)
        public
        view
        returns (
            string memory _name,
            string memory _tokenImageUri,
            address _creator,
            uint256 _classCount,
            uint256 _openTime,
            uint256 _startTime,
            uint256 _closeTime,
            uint256 _endTime
        )
    {
        _name = _events[_eventId].name;
        _tokenImageUri = _events[_eventId].tokenImageUri;
        _creator = _events[_eventId].creator;
        _classCount = _events[_eventId].classCount;
        _openTime = _events[_eventId].openTime;
        _closeTime = _events[_eventId].closeTime;
        _startTime = _events[_eventId].startTime;
        _endTime = _events[_eventId].endTime;
    }

    // 이벤트 클래스 조회
    function getEventClass(uint256 _eventId, uint8 _eventClassId)
        public
        view
        returns (EventClass memory)
    {
        return _events[_eventId].class[_eventClassId];
    }

    // 티켓 토큰 민트
    function mintToken(
        uint256 _eventId,
        uint8 _tokenType, // 0 : NFT, 1: SBT
        uint8 _classId,
        uint256 _number,
        string memory _tokenUri
    ) public override onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 _newTokenId = _tokenIds.current();
        _safeMint(msg.sender, _newTokenId);
        _setTokenURI(_newTokenId, _tokenUri);

        _events[_eventId].class[_classId].tokens[_number] = _newTokenId;

        _tokenExtentions[_newTokenId] = TokenExtention({
            eventId: _eventId,
            tokenType: _tokenType,
            isTrade: true
        });

        return _eventId;
    }

    // 토큰 구매
    function buyToken(
        uint256 _eventId,
        uint8 _classId,
        uint256 _number,
        bool _isSelect
    ) public payable override isSale(_eventId) {
        require(
            _events[_eventId].class[_classId].price * 1 ether == msg.value,
            "This amount is not the same."
        );
        require(
            _events[_eventId].openTime < block.timestamp,
            "This time is not open."
        );
        require(
            block.timestamp < _events[_eventId].closeTime,
            "The time is close."
        );
        require(
            _events[_eventId].class[_classId].ownerTotal <=
                _events[_eventId].class[_classId].count,
            "Sold out."
        );

        uint256 _tokenId;

        // 자리를 선택하는 경우
        if (_isSelect) {
            _tokenId = _events[_eventId].class[_classId].tokens[_number];
            // 자리를 선택 하지 않는 경우
        } else {
            for (
                uint256 i = _events[_eventId].class[_classId].index;
                i < _events[_eventId].class[_classId].count;
                i++
            ) {
                _tokenId = _events[_eventId].class[_classId].tokens[i];
                if (_tokenExtentions[_tokenId].isTrade) {
                    break;
                }
            }
        }
        require(
            _tokenExtentions[_tokenId].isTrade,
            "This token is not traded."
        );
        address _owner = owner();
        _transfer(_owner, msg.sender, _tokenId);
        _events[_eventId].class[_classId].owners[_number] = msg.sender;
        _tokenExtentions[_tokenId].isTrade = false;
        _events[_eventId].class[_classId].ownerTotal += 1;
        _amounts[_eventId] += msg.value;
    }

    // 토큰 구매자 조회
    function getTokenBuyers(uint256 _eventId, uint8 _classId)
        public
        view
        override
        returns (address[] memory)
    {
        return _events[_eventId].class[_classId].owners;
    }

    // 이벤트 토큰 응모
    function applyToken(uint256 _eventId, uint8 _classId)
        public
        payable
        override
        isEntry(_eventId)
    {
        require(
            _events[_eventId].class[_classId].price * 1 ether == msg.value,
            "This amount is not the same."
        );
        require(
            _events[_eventId].openTime < block.timestamp,
            "This time is not open."
        );
        require(
            block.timestamp < _events[_eventId].closeTime,
            "The time is close."
        );
        // 중복 신청 방지
        for (uint256 i = 0; i < _eventParticipants[_eventId].length; i++) {
            require(
                _eventParticipants[_eventId][i] != msg.sender,
                "You already applied."
            );
        }
        _eventParticipants[_eventId].push(msg.sender);
        _amounts[_eventId] += msg.value;
    }

    // 이벤트 응모자 조회
    function getEventParticipants(uint256 _eventId)
        public
        view
        override
        returns (address[] memory)
    {
        return _eventParticipants[_eventId];
    }

    function _eventWinners(uint256 _eventId, uint8 _eventClassId) private {
        uint256 _randNum = 0;
        address _temp;
        for (uint256 j = 0; j < 10; j++) {
            _randNum =
                uint256(
                    keccak256(
                        abi.encodePacked(j + block.timestamp, block.difficulty)
                    )
                ) %
                _eventParticipants[_eventId].length;

            _temp = _eventParticipants[_eventId][j];
            _eventParticipants[_eventId][j] = _eventParticipants[_eventId][
                _randNum
            ];
            _eventParticipants[_eventId][_randNum] = _temp;
        }
        for (uint256 j = _eventParticipants[_eventId].length; j > 0; j--) {
            _randNum =
                uint256(
                    keccak256(
                        abi.encodePacked(j + block.timestamp, block.difficulty)
                    )
                ) %
                _eventParticipants[_eventId].length;
            address temp = _eventParticipants[_eventId][j];
            _eventParticipants[_eventId][j] = _eventParticipants[_eventId][
                _randNum
            ];
            _eventParticipants[_eventId][_randNum] = temp;
        }
    }

    function transferEventWinner(uint256 _eventId, uint8 _eventClassId)
        public
        override
        onlyOwner
        returns (address[] memory)
    {
        require(
            _isEventWinners[_eventId] == false,
            "Already selected the winners."
        );
        address _owner = owner();
        _eventWinners(_eventId, _eventClassId);

        for (uint256 i = 0; i < _eventParticipants[_eventId].length; i++) {
            _transfer(
                _owner,
                _eventParticipants[_eventId][i],
                _events[_eventId].class[_eventClassId].tokens[i]
            );
            _events[_eventId].class[_eventClassId].owners[
                i
            ] = _eventParticipants[_eventId][i];
        }

        // 이벤트를 응모에서 판매 상태로 변경
        _events[_eventId].eventType = 0;
        _isEventWinners[_eventId] = true;

        return _events[_eventId].class[_eventClassId].owners;
    }

    function endEvent(uint256 _eventId, uint8 _eventEndStatus)
        public
        override
        onlyOwner
        isEndEvent(_eventId)
    {
        uint256 _deposit = _deposits[_eventId];
        uint256 _compensation = 0; // 실패 시 사용자 보상
        address _owner = owner();

        // 이벤트가 성공적으로 이루어진 경우
        if (_eventEndStatus == 1) {
            payable(_events[_eventId].creator).transfer(
                _amounts[_eventId] + _deposit
            );

            // 이벤트가 실패한 경우
        } else if (_eventEndStatus == 0) {
            uint8 _eventType = _events[_eventId].eventType;

            // Sale
            if (_eventType == 0) {
                for (uint8 i = 0; i < _events[_eventId].classCount; i++) {
                    if (_events[_eventId].class[i].price == 0) continue;
                    uint256 _compensation = _events[_eventId].class[i].price *
                        1 ether;
                    _compensation = _compensation + ((_compensation / 100) * 3);
                    for (
                        uint256 j = 0;
                        j < _events[_eventId].class[i].owners.length;
                        i++
                    ) {
                        // address가 0이 아닐 경우 보상
                        if (
                            _events[_eventId].class[i].owners[j] != address(0)
                        ) {
                            payable(_events[_eventId].class[i].owners[j])
                                .transfer(
                                    _events[_eventId].class[i].price +
                                        _compensation
                                );
                        }
                    }
                }
                // Entry
            } else if (_eventType == 1) {
                _compensation = _deposit / _eventParticipants[_eventId].length;
                for (
                    uint256 i = 0;
                    i < _eventParticipants[_eventId].length;
                    i++
                ) {
                    payable(_eventParticipants[_eventId][i]).transfer(
                        _compensation
                    );
                }
            }
        }
    }

    /**
     * @dev See {IKIP17-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override isEndEvent(tokenId) isNFT(tokenId) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "KIP17: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IKIP17-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override isEndEvent(tokenId) isNFT(tokenId) {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IKIP17-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override isEndEvent(tokenId) isNFT(tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "KIP17: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the KIP17/ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IKIP17Receiver-onKIP17Received}
     *   OR {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual override isEndEvent(tokenId) isNFT(tokenId) {
        revert();
        // _transfer(from, to, tokenId);
        // require(
        //     _checkOnKIP17Received(from, to, tokenId, _data) ||
        //         _checkOnERC721Received(from, to, tokenId, _data),
        //     "KIP17: transfer to non IKIP17Receiver/IERC721Receiver implementer"
        // );
    }
}