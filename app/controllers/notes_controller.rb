class NotesController < InertiaController
  before_action :set_client
  before_action :set_note, only: %i[update destroy]

  # Searchable within a client (NT-3).
  def index
    notes = @client.notes.search(params[:q]).recent
    render inertia: "Clients/Notes", props: {
      client: { id: @client.id, name: @client.full_name },
      filters: params.permit(:q, :tag).to_h,
      tags: Note::TAGS,
      notes: notes.select { |n| params[:tag].blank? || n.tag == params[:tag] }
                  .map { |n| serialize(n) }
    }
  end

  def create
    note = @client.notes.new(note_params)
    if note.save
      redirect_back fallback_location: client_notes_path(@client), notice: "Note added."
    else
      redirect_back fallback_location: client_notes_path(@client),
        inertia: { errors: note.errors.to_hash(true) }
    end
  end

  def update
    @note.update(note_params)
    redirect_back fallback_location: client_notes_path(@client)
  end

  def destroy
    @note.destroy
    redirect_back fallback_location: client_notes_path(@client), notice: "Note deleted."
  end

  private

  def set_client = @client = current_trainer.clients.find(params[:client_id])
  def set_note   = @note = @client.notes.find(params[:id])

  def note_params = params.permit(:body, :tag, :is_pinned, :noted_at)

  def serialize(note)
    { id: note.id, body: note.body, tag: note.tag,
      isPinned: note.is_pinned, notedAt: note.noted_at }
  end
end
