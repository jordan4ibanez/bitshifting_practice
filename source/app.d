import std.stdio;
import std.bitmanip;


// Welcome to my mini bitshifting tutorial in D, have fun
void main() {
    // We have our base value
    // Many values in 1 memory address
	uint dataPack = 0;

    /*
    Represent it in literal bits like so
    32 bits unsigned = literally just 32 zeros

    | 0000 0000 0000 0000 | 0000 | 0000 | 0000 | 0000 |
    | id    65535         | bs 15| tl 15| nl 15|rot 15|
    id: block id
    bs: block state
    tl: torch light
    nl: natural light
    rot: rotation
    */

    // Let's plop in some fancy data

    // This is actually 4 bits! We cannot exceed 15! If we do, you'll overflow into the next register!
    ubyte rotation = 15;

    // We could run an assertion to double check!
    // assert(rotation < 16, "Warning rotation has overflowed!");

    // Of course we will want to warn the user of the api that this happened instead
    if (rotation > 15) {
        writeln("Warning: rotation has overflowed!");
    }
    

    // But what if we're in release mode with a user completely going crazy with the api?
    // This is why we're going to manually overflow it, it's crazy, but it also prevents insane behavior down the line
    rotation = cast(ubyte)(rotation << 4) >> 4;
    // What we are doing is basically shoveling the data 0001_0000 into 0000_0000 and then reculling the data off the end
    // If you would like to see this in action, comment out the line above, then uncomment these lines and mess with rotation!
    /*
    writefln("Rotation as is:\n%08b", rotation);
    rotation = cast(ubyte)(rotation << 4);
    writefln("Rotation shifted out:\n%08b", rotation);
    rotation = rotation >> 4;
    writefln("Rotation shifted back in:\n%08b", rotation);
    */

    // How did we shift those bits?? Well, that's where the << and >> operators comes in! It simply moved it over 4 bits and then back again

    // Now shovel it into the bits of the dataPack, right at the end
    dataPack |= rotation;

    // "|" the thing above the enter key on qwerty keyboards, is a bitwise OR. We take the highest data which is 1 and keep it!

    // Now we can print it out as raw bits!
    writefln("Here are your fancy bits:\n%032b", dataPack);

    // Very fancy yes. You see the 4 ones at the end, this is a 4 bit representation of 15
    // But what if we want MOAR data in there? We'll overwrite the existing things! This is where bitshifting comes into full force!
    // Let's plop in natural light! And yes, this was written as I'm literally using it in a mc clone :P

    ubyte naturalLight = 15;

    // Seems a little tedious to keep writing out the bit overflow implementation over and over.
    // Let's write a built in function below, we'll label it...overflow4Bit()
    overflow4Bit(naturalLight);

    // Great! We've limited our computational capabilities to 4 bit! Now what?
    // Well, we have to append this new fancy data into the dataPack!
    dataPack |= naturalLight << 4;

    // As you can see, we have shifted it left 4 bits, then utilized "|" bitwise or to append it, so all zeros in the 4 bit padding
    // "0000" 0000 the quoted part in a ubyte, gets completely ignored!

    // Let's print it out again, with a new label
    writefln("Here are your fancy bits. Now with light!\n%032b", dataPack);

    // But what happens when we change rotation again?
    rotation = 0;
    overflow4Bit(rotation);
    dataPack |= rotation;

    writefln("Here are your fancy bits. We tried to change the rotation:\n%032b", dataPack);

    // Nothing changed, we're going to get to that though!

    // Let's start by filling the dataPack with the rest of our data!
    ubyte torchLight = 15;
    overflow4Bit(torchLight);
    ubyte blockState = 15;
    overflow4Bit(blockState);
    ushort blockID = 65_535;
    // ushort automatically overflows, it is a language defined type!

    dataPack |= (torchLight << 8);
    writefln("Added torchLight:\n%032b", dataPack);
    dataPack |= (blockState << 12);
    writefln("Added blockState:\n%032b", dataPack);
    dataPack |= (blockID << 16);
    writefln("Added blockID:\n%032b", dataPack);

    // Wow, that's a lot of ones! But how the heck do we even work with this???
    // Well, let's write some functions below!

    writeln("rotation: ",        getRotation(dataPack));
    writeln("natural light: ",   getNaturalLight(dataPack));
    writeln("torch light: ",     getTorchLight(dataPack));
    writeln("block state: ",     getBlockState(dataPack));
    writeln("block id: ",        getBlockID(dataPack));

    // What is happening below is literally culling the data off of the uint into whatever data type we need!
    /*
    For example with rotation!

    In this example, the dataPack is: 4_294_967_295 as a raw uint value

    we start with 1111_1111_1111_1111_1111_1111_1111_|1111| <- this is what we want

    We run: data << 28 and it shifts 28 bits like so!
    |1111|_0000_0000_0000_0000_0000_0000_0000

    Then we run: data >> 28 and it shifts it back into a usable position
    0000_0000_0000_0000_0000_0000_0000_|1111|

    Then the final cast trims it into a smaller memory container like so: cast(ubyte)
    0000_|1111|

    Now we have 15!

    Think of this as...shaking off or smashing apart the bits we don't want to get the bits we do!
    */

    // Okay we can get individual values from this one memory address. That's great!
    // But how do we change this data in the dataPack?
    // Well that's the thing, we actually have to reassemble the value from it's core components
    // See the section commented: Wow this is fancy!

    // Now let's try that rotation modification again using the internal api!

    setRotation(dataPack, rotation);

    writefln("Here are your fancy bits. We changed the rotation using the api!\n%032b", dataPack);

    // This time it worked!
    // The best part is: This is all happening on the cpu until the new value is set in ram! It's free real estate on the cache!

    // Now let's do something silly

    blockID = 1;
    blockState = 2;
    torchLight = 3;
    naturalLight = 4;
    rotation = 5;
    setBlockID(dataPack, blockID);
    setBlockState(dataPack, blockState);
    setTorchLight(dataPack, torchLight);
    setNaturalLight(dataPack, naturalLight);
    setRotation(dataPack, rotation);

    writeln("I can count!\n",
        getBlockID(dataPack), "\n",
        getBlockState(dataPack), "\n",
        getTorchLight(dataPack), "\n",
        getNaturalLight(dataPack), "\n",
        getRotation(dataPack), "\n",
        "Wow!"
    );

    // Now let's see the mess of bits in the raw packed form!
    writefln("Here is that disaster!\n%032b", dataPack);

    // I hope you have fun writing out your custom bitpacking api, and I hope you have fun!
}


// Hello, welcome to my built in function thing, same thing as above, less verbose
void overflow4Bit(ref ubyte data) {
    if (data > 15) {
        writeln("Warning: data has overflowed!");
    }
    data = cast(ubyte)(data << 4) >> 4;
}


// This is where the fun begins
ubyte getRotation(uint input) {
    return cast(ubyte)((input << 28) >> 28);
}
ubyte getNaturalLight(uint input) {
    return cast(ubyte)((input << 24) >> 28);
}
ubyte getTorchLight(uint input) {
    return cast(ubyte)((input << 20) >> 28);
}
ubyte getBlockState(uint input) {
    return cast(ubyte)((input << 16) >> 28);
}
ushort getBlockID(uint input) {
    // Block state is the last 16 bits to the left, we only need to cull the right
    return cast(ushort)(input >> 16);
}

// Wow this is complicated!
// Note: we are doing a bit modification via reassembly!
// Every component that changes must get the other parts to have a correct new value
void setRotation(ref uint input, ubyte newRotation) {
    ubyte naturalLight = getNaturalLight(input);
    ubyte torchLight = getTorchLight(input);
    ubyte blockState = getBlockState(input);
    ushort blockID = getBlockID(input);
    input = reassemble(newRotation, naturalLight, torchLight, blockState, blockID);
}
void setNaturalLight(ref uint input, ubyte newNaturalLight) {
    ubyte rotation = getRotation(input);
    ubyte torchLight = getTorchLight(input);
    ubyte blockState = getBlockState(input);
    ushort blockID = getBlockID(input);
    input = reassemble(rotation, newNaturalLight, torchLight, blockState, blockID);
}
void setTorchLight(ref uint input, ubyte newTorchLight) {
    ubyte rotation = getRotation(input);
    ubyte naturalLight = getNaturalLight(input);
    ubyte blockState = getBlockState(input);
    ushort blockID = getBlockID(input);
    input = reassemble(rotation, naturalLight, newTorchLight, blockState, blockID);
}
void setBlockState(ref uint input, ubyte newBlockState) {
    ubyte rotation = getRotation(input);
    ubyte naturalLight = getNaturalLight(input);
    ubyte torchLight = getTorchLight(input);
    ushort blockID = getBlockID(input);
    input = reassemble(rotation, naturalLight, torchLight, newBlockState, blockID);
}
void setBlockID(ref uint input, ushort newBlockID) {
    ubyte rotation = getRotation(input);
    ubyte naturalLight = getNaturalLight(input);
    ubyte torchLight = getTorchLight(input);
    ubyte blockState = getBlockState(input);
    input = reassemble(rotation, naturalLight, torchLight, blockState, newBlockID);
}

// This function allows a LOT less boilerplate!
uint reassemble(
    ubyte rotation,
    ubyte naturalLight,
    ubyte torchLight,
    ubyte blockState,
    ushort blockID ) {

    // Why yes, we can construct a blank slate of bits in the return statement!
    return cast(uint)(0) | rotation | (naturalLight << 4) | (torchLight << 8) | (blockState << 12) | (blockID << 16);
}
