class_name SpringUtils

static func calc_damped_spring_motion_params(delta_time: float, angular_frequency: float, damping_ratio: float) -> DampedSpringMotionParams:
	var epsilon: float = 0.0001
	var params: DampedSpringMotionParams = DampedSpringMotionParams.new()

	if damping_ratio < 0.0:
		damping_ratio = 0.0
	if angular_frequency < 0.0:
		angular_frequency = 0.0

	if angular_frequency < epsilon:
		params.pos_pos_coef = 1.0
		params.pos_vel_coef = 0.0
		params.vel_pos_coef = 0.0
		params.vel_vel_coef = 1.0
		return params

	if damping_ratio > 1.0 + epsilon:
		# Overdamped
		var za: float = - angular_frequency * damping_ratio
		var zb: float = angular_frequency * sqrt(damping_ratio * damping_ratio - 1.0)
		var z1: float = za - zb
		var z2: float = za + zb

		var e1: float = exp(z1 * delta_time)
		var e2: float = exp(z2 * delta_time)

		var inv_two_zb: float = 1.0 / (2.0 * zb)
		var e1_over: float = e1 * inv_two_zb
		var e2_over: float = e2 * inv_two_zb
		var z1e1_over: float = z1 * e1_over
		var z2e2_over: float = z2 * e2_over

		params.pos_pos_coef = e1_over * z2 - z2e2_over + e2
		params.pos_vel_coef = - e1_over + e2_over
		params.vel_pos_coef = (z1e1_over - z2e2_over + e2) * z2
		params.vel_vel_coef = - z1e1_over + z2e2_over

	elif damping_ratio < 1.0 - epsilon:
		# Underdamped
		var omega_zeta: float = angular_frequency * damping_ratio
		var alpha: float = angular_frequency * sqrt(1.0 - damping_ratio * damping_ratio)

		var exp_term: float = exp(-omega_zeta * delta_time)
		var cos_term: float = cos(alpha * delta_time)
		var sin_term: float = sin(alpha * delta_time)
		var inv_alpha: float = 1.0 / alpha

		var exp_sin: float = exp_term * sin_term
		var exp_cos: float = exp_term * cos_term
		var exp_ozs_oa: float = exp_term * omega_zeta * sin_term * inv_alpha

		params.pos_pos_coef = exp_cos + exp_ozs_oa
		params.pos_vel_coef = exp_sin * inv_alpha
		params.vel_pos_coef = - exp_sin * alpha - omega_zeta * exp_ozs_oa
		params.vel_vel_coef = exp_cos - exp_ozs_oa

	else:
		# Critically damped
		var exp_term: float = exp(-angular_frequency * delta_time)
		var time_exp: float = delta_time * exp_term
		var time_exp_freq: float = time_exp * angular_frequency

		params.pos_pos_coef = time_exp_freq + exp_term
		params.pos_vel_coef = time_exp
		params.vel_pos_coef = - angular_frequency * time_exp_freq
		params.vel_vel_coef = - time_exp_freq + exp_term

	return params

static func update_damped_spring_motion(pos_vel: PosVel, equilibrium_pos: float, params: DampedSpringMotionParams) -> PosVel:
	var old_pos: float = pos_vel.pos - equilibrium_pos
	var old_vel: float = pos_vel.vel

	pos_vel.pos = old_pos * params.pos_pos_coef + old_vel * params.pos_vel_coef + equilibrium_pos
	pos_vel.vel = old_pos * params.vel_pos_coef + old_vel * params.vel_vel_coef

	return pos_vel;
