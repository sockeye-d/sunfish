#ifndef SUNFISH_STREAMPEERFILE_H
#define SUNFISH_STREAMPEERFILE_H

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/stream_peer_extension.hpp>

class StreamPeerFile final : public godot::StreamPeerExtension {
	GDCLASS(StreamPeerFile, StreamPeerExtension);

protected:
	static void _bind_methods();

private:
	godot::Ref<godot::FileAccess> m_fd;

public:
	godot::Error _get_data(uint8_t* r_buffer, int32_t r_bytes, int32_t* r_received) override;
	godot::Error _get_partial_data(uint8_t* r_buffer, int32_t r_bytes, int32_t* r_received) override;
	godot::Error _put_data(const uint8_t* p_data, int32_t p_bytes, int32_t* r_sent) override;
	godot::Error _put_partial_data(const uint8_t* p_data, int32_t p_bytes, int32_t* r_sent) override;
	int32_t _get_available_bytes() const override;

	[[nodiscard]] godot::Ref<godot::FileAccess> get_file_access() const { return m_fd; }

	static StreamPeerFile *open(const godot::String &p_path, godot::FileAccess::ModeFlags p_mode);
	static StreamPeerFile *from(const godot::Ref<godot::FileAccess>& p_fd);
};

#endif // SUNFISH_STREAMPEERFILE_H
