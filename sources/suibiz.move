
module suibiz::note;

public struct Note has key, store {
    id: UID,
    content: vector<u8>,
}

/// Create a new note and transfer to creator
public entry fun create_note(content: vector<u8>, ctx: &mut TxContext) {
    let note = Note {
        id: object::new(ctx),
        content,
    };
    transfer::transfer(note, ctx.sender());
}

/// Delete a note (not truly deleting, just consuming)
public entry fun delete_note(note: Note) {
    let Note { id, content: _ } = note;
    sui::object::delete(id);
}
