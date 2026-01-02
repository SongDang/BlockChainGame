
message Add {
    amount: Int as uint32;
}

const NANO: Int = 1000000000; // 1 TON = 10^9 basic units
// Prices for in-game items (in basic units)
const HEART_PRICE: Int = NANO / 10; // 0.1 TON
const LASER_PRICE: Int = NANO / 5;  // 0.2 TON
const GOLD_PRICE: Int = NANO / 100; // 0.01 TON
const DIAMOND_PRICE: Int = NANO / 10; // 0.1 TON
const WIN_PRICE: Int = NANO / 10; // 0.1 TON
const UPGRADE_PRICE: Int = NANO / 1; // 1 TON

message Deposit {}  // send TON to get score
message(0x8c3e43c4) Reward1Ton {}
message Reward { amountReward: Int as coins; } // owner reward amount in nanotons
// Purchase messages for items
message BuyHeart { qty: Int as uint32; }
message BuyLaser { qty: Int as uint32; }
// Messages to consume (use) items from client
message UseHeart { qty: Int as uint32; }
message UseLaser { qty: Int as uint32; }
message GetScore { player: Address; }
message RewardHeart {}
message Upgrade { upgradeType: Int as uint32; }

contract HelloWorld(
    // Persistent state variables declared via the
    // contract parameters syntax, which was introduced in v1.6.0
    //
    // See: https://docs.tact-lang.org/book/contracts/#parameters
    id: Int as uint32,
    counter: Int as uint32,



    // owner address 
    owner: Address,
    // rate: how many score per 1 TON (not per basic unit)
    ratePerTon: Int as uint32,    // pass 100 for 1 TON => 100 score
    // persistent mapping: player address -> score
    scores: map<Address, Int>,
    heart: map<Address, Int>,
    laser: map<Address, Int>,
    lastTimeReceiveHeart: map<Address, Int>,
    levelHeart: map<Address, Int>,
    levelDig: map<Address, Int>,
    levelOre: map<Address, Int>
) {

    // Empty receiver for the deployment,
    // which expects the `null` message body
    // receive() {
    //     // Forward the remaining value in the
    //     // incoming message back to the sender
    //     cashback(sender());
    // }
    receive(msg: Add) {
        self.counter += msg.amount;

        // Forward the remaining value in the
        // incoming message back to the sender
        // cashback(sender());
    }
    get fun counter(): Int {
        return self.counter;
    }
    get fun id(): Int {
        return self.id;
    }


    // helper: require owner
    fun onlyOwner() {
        require(sender() == self.owner,"OnlyOwner!"); // error if not owner
    }

    // default receive without message: treat as Deposit
    receive() {
        // value() returns amount of basic units sent with message
        let paid: Int = context().value;


        // compute score increment:
        // scoreInc = floor( (paid / NANO) * ratePerTon )
        // compute integer: (paid * ratePerTon) / NANO
        let scoreInc: Int = (paid * self.ratePerTon) / NANO;

        // add to player's score
        let p: Address = sender();
        let prevTemp: Int? = self.scores.get(p);
        let prev: Int = 0;

        //Check null value, convert to Int
        if (prevTemp == null) {
            prev = 0;
        }
        else {
            prev = prevTemp!!;
        }

        self.scores.set(p, prev + scoreInc);

        // keep the money in contract (no cashback) — contract balance increases
    }

    // explicit Deposit message (identical to bare receive)
    receive(msg: Deposit) {
        let paid: Int = context().value;
        let scoreInc: Int = (paid * self.ratePerTon) / NANO;
        let p: Address = sender();
        let prevTemp: Int? = self.scores.get(p);
        let prev: Int = 0;

        if (prevTemp == null) {
            prev = 0;
        }
        else {
            prev = prevTemp!!;
        }
        self.scores.set(p, prev + scoreInc);
    }

    // Owner rewards a player: transfers TON from contract balance to player
    receive(msg: Reward) {
        //self.onlyOwner();
        let p: Address = sender();
        // amount is in nanotons
        let amountReward: Int = msg.amountReward;

        //Get opcode
        let currentOpcode: Int = Reward.opcode();
        dump("Opcode Reward");
        dump(currentOpcode);

        // Basic safety: check contract has enough balance
        // balance() returns current contract balance (basic units)
        require(myBalance() >= amountReward, "Insufficient"); // error if insufficient

        // transfer amount to player
        send(SendParameters{
            to: p,
            value: amountReward,
            bounce: true, // Optional: Message will bounce back on error (default behavior)
            mode: 0, // Optional: Recommended mode for transfers
        });
    }

    receive(msg: Reward1Ton) {
        //self.onlyOwner();
        let p: Address = sender();
        // amount is in nanotons
        let amountReward: Int = 1000000000;

        //Get opcode
        let currentOpcode: Int = Reward.opcode();
        dump("Opcode Reward");
        dump(currentOpcode);

        // Basic safety: check contract has enough balance
        // balance() returns current contract balance (basic units)
        
    }

    // Query player's score (getter)
    get 
    fun get_score(p: Address): Int {
        let scorePlayer: Int? = self.scores.get(p);
        if(scorePlayer == null) {
            return 0;
        }
        return scorePlayer!!;
    }

    // Query contract balance (basic units)
    get fun get_balance(): Int {
        return myBalance();
    }

    // Query owner
    get fun get_owner(): Address {
        return self.owner;
    }

    // Query rate
    get fun get_rate(): Int {
        return self.ratePerTon;
    }

    // ========== Item management: heart & laser ==========
    // Get heart count for player
    get fun get_heart(p: Address): Int {
        let v: Int? = self.heart.get(p);
        if (v == null) { return 0; }
        return v!!;
    }

    // Get laser count for player
    get fun get_laser(p: Address): Int {
        let v: Int? = self.laser.get(p);
        if (v == null) { return 0; }
        return v!!;
    }

    // Get price gold
    get fun get_price_gold(): Int {
        return GOLD_PRICE;
    }

    // Get price diamond
    get fun get_price_diamond(): Int {
        return DIAMOND_PRICE;
    }

    // Get price win
    get fun get_price_win(): Int {
        return WIN_PRICE;
    }

    // Get price upgrade
    get fun get_price_upgrade(): Int {
        return UPGRADE_PRICE;
    }

    // Get lastTimeReceiveHeart for player
    get fun get_lastTimeReceiveHeart(p: Address): Int {
        let v: Int? = self.lastTimeReceiveHeart.get(p);
        if (v == null) { return 0; }
        return v!!;
    }

    // Get levelHeart for player
    get fun get_levelHeart(p: Address): Int {
        let v: Int? = self.levelHeart.get(p);
        if (v == null) { return 0; }
        return v!!;
    }

    // Get levelDig for player
    get fun get_levelDig(p: Address): Int {
        let v: Int? = self.levelDig.get(p);
        if (v == null) { return 0; }
        return v!!;
    }

    // Get levelOre for player
    get fun get_levelOre(p: Address): Int {
        let v: Int? = self.levelOre.get(p);
        if (v == null) { return 0; }
        return v!!;
    }

    // Buy hearts
    receive(msg: BuyHeart) {
        let qty: Int = msg.qty;
        require(qty > 0, "InvalidQty");
        let price: Int = HEART_PRICE * qty;
        let paid: Int = context().value;
        require(paid >= price, "InsufficientFunds");

        let p: Address = sender();
        let prevTemp: Int? = self.heart.get(p);
        let prev: Int = 0;
        if (prevTemp == null) { prev = 0; } else { prev = prevTemp!!; }
        self.heart.set(p, prev + qty);

        let change: Int = paid - price;
        if (change > 0) {
            send(SendParameters{
                to: p,
                value: change,
                bounce: true,
                mode: 0,
            });
        }
    }

    // Buy lasers
    receive(msg: BuyLaser) {
        let qty: Int = msg.qty;
        require(qty > 0, "InvalidQty");
        let price: Int = LASER_PRICE * qty;
        let paid: Int = context().value;
        require(paid >= price, "InsufficientFunds");

        let p: Address = sender();
        let prevTemp: Int? = self.laser.get(p);
        let prev: Int = 0;
        if (prevTemp == null) { prev = 0; } else { prev = prevTemp!!; }
        self.laser.set(p, prev + qty);

        let change: Int = paid - price;
        if (change > 0) {
            send(SendParameters{
                to: p,
                value: change,
                bounce: true,
                mode: 0,
            });
        }
    }

    // Use (consume) items via message from client
    receive(msg: UseHeart) {
        let qty: Int = msg.qty;
        require(qty > 0, "InvalidQty");
        let p: Address = sender();
        let curTemp: Int? = self.heart.get(p);
        let cur: Int = 0;
        if (curTemp == null) { cur = 0; } else { cur = curTemp!!; }
        require(cur >= qty, "InsufficientHeart");
        self.heart.set(p, cur - qty);
    }

    receive(msg: UseLaser) {
        let qty: Int = msg.qty;
        require(qty > 0, "InvalidQty");
        let p: Address = sender();
        let curTemp: Int? = self.laser.get(p);
        let cur: Int = 0;
        if (curTemp == null) { cur = 0; } else { cur = curTemp!!; }
        require(cur >= qty, "InsufficientLaser");
        self.laser.set(p, cur - qty);
    }

    // Reward hearts based on levelHeart
    receive(msg: RewardHeart) {
        let p: Address = sender();
        let level: Int = self.get_levelHeart(p);
        let heartsToAdd: Int = 0;
        if (level == 1) {
            heartsToAdd = 3;
        } else if (level == 2) {
            heartsToAdd = 4;
        } else {
            // level 0
            heartsToAdd = 2;
        }
        let prevTemp: Int? = self.heart.get(p);
        let prev: Int = 0;
        if (prevTemp != null) { prev = prevTemp!!; }
        self.heart.set(p, prev + heartsToAdd);
        self.lastTimeReceiveHeart.set(p, now());
    }

    // Upgrade levels
    receive(msg: Upgrade) {
        let p: Address = sender();

        // 1. Check tiền gửi vào
        let paid: Int = context().value;
        require(paid >= UPGRADE_PRICE, "Need 1 TON to upgrade");

        // 2. Upgrade theo type
        let type: Int = msg.upgradeType;

        if (type == 1) {
            let prev: Int = self.get_levelDig(p);
            self.levelDig.set(p, prev + 1);
        } 
        else if (type == 2) {
            let prev: Int = self.get_levelHeart(p);
            self.levelHeart.set(p, prev + 1);
        } 
        else {
            let prev: Int = self.get_levelOre(p);
            self.levelOre.set(p, prev + 1);
        } 
        

        // 3. Trả lại tiền dư (nếu có)
        let change: Int = paid - UPGRADE_PRICE;
        if (change > 0) {
        send(SendParameters{
            to: p,
            value: change,
            bounce: true,
            mode: 0,
        });
        }
    }
}

